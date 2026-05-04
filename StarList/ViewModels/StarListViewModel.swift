import Foundation

enum SortOption: String, CaseIterable {
    case starredAt = "starred_at"
    case name = "name"
    case stars = "stars"
    case updated = "updated"

    var displayName: String {
        switch self {
        case .starredAt: return "收藏时间"
        case .name: return "名称"
        case .stars: return "Star数"
        case .updated: return "更新时间"
        }
    }
}

enum GroupOption: String, CaseIterable {
    case none = "none"
    case language = "language"

    var displayName: String {
        switch self {
        case .none: return "无分组"
        case .language: return "按语言"
        }
    }
}

@MainActor
final class StarListViewModel: ObservableObject {
    @Published var repos: [StarredRepo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var sortOption: SortOption = .starredAt
    @Published var groupOption: GroupOption = .none
    @Published var isFromCache = false

    private let githubService = GitHubService()
    private let cache = RepoCache.shared

    var filteredRepos: [StarredRepo] {
        var result = repos
        if !searchText.isEmpty {
            result = result.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.language?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                $0.topics.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        return sorted(result)
    }

    var groupedRepos: [(String, [StarredRepo])] {
        let filtered = filteredRepos
        switch groupOption {
        case .none:
            return [("", filtered)]
        case .language:
            let grouped = Dictionary(grouping: filtered) { $0.language ?? "其他" }
            return grouped.sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
        }
    }

    private func sorted(_ repos: [StarredRepo]) -> [StarredRepo] {
        switch sortOption {
        case .starredAt:
            return repos.sorted { ($0.starredAt ?? "") > ($1.starredAt ?? "") }
        case .name:
            return repos.sorted { $0.fullName.localizedStandardCompare($1.fullName) == .orderedAscending }
        case .stars:
            return repos.sorted { $0.stargazersCount > $1.stargazersCount }
        case .updated:
            return repos.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    func loadFromCache() {
        if let cached = cache.load(), !cached.isEmpty {
            repos = cached
            isFromCache = true
        }
    }

    func fetchAll(settings: AppSettings) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        isFromCache = false
        defer { isLoading = false }

        do {
            let allRepos = try await githubService.fetchAllStarredRepos(settings: settings)
            repos = allRepos
            cache.save(allRepos)
        } catch {
            if repos.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }
}
