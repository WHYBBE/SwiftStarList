import Foundation

@MainActor
final class StarListViewModel: ObservableObject {
    @Published var repos: [StarredRepo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var currentPage = 1
    @Published var hasMorePages = true

    private let githubService = GitHubService()

    var filteredRepos: [StarredRepo] {
        if searchText.isEmpty { return repos }
        return repos.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.language?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    func loadRepos(settings: AppSettings) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let newRepos = try await githubService.fetchStarredRepos(page: currentPage, settings: settings)
            if newRepos.count < 100 { hasMorePages = false }
            if currentPage == 1 {
                repos = newRepos
            } else {
                repos.append(contentsOf: newRepos)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore(settings: AppSettings) async {
        guard hasMorePages, !isLoading else { return }
        currentPage += 1
        await loadRepos(settings: settings)
    }

    func refresh(settings: AppSettings) async {
        currentPage = 1
        hasMorePages = true
        await loadRepos(settings: settings)
    }
}
