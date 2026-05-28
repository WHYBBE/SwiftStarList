import Foundation

@MainActor
final class RepoDetailViewModel: ObservableObject {
    @Published var readmeContent: String?
    @Published var analysis: String?
    @Published var isLoadingREADME = false
    @Published var isLoadingAnalysis = false
    @Published var errorMessage: String?

    private let githubService = GitHubService()
    private let llmService = LLMService()

    @Published var recentTags: [RepoTag] = []
    @Published var recentCommits: [RepoCommit] = []
    @Published var recentReleases: [RepoRelease] = []
    @Published var isLoadingActivity = false

    func reset() {
        readmeContent = nil
        analysis = nil
        errorMessage = nil
        isLoadingREADME = false
        isLoadingAnalysis = false
        recentTags = []
        recentCommits = []
        recentReleases = []
        isLoadingActivity = false
    }

    func fetchREADME(repo: StarredRepo, settings: AppSettings) async {
        isLoadingREADME = true
        defer { isLoadingREADME = false }

        do {
            readmeContent = try await githubService.fetchREADME(
                owner: repo.owner.login,
                repo: repo.name,
                settings: settings
            )
        } catch {
            readmeContent = L.s.cannotGetReadme
        }
    }

    func analyzeRepo(repo: StarredRepo, settings: AppSettings) async {
        if readmeContent == nil {
            await fetchREADME(repo: repo, settings: settings)
        }

        guard let readme = readmeContent, !readme.hasPrefix(L.s.cannotGetReadme) else {
            errorMessage = L.s.readReadmeFirst
            return
        }

        guard !settings.llmConfig.apiKey.isEmpty else {
            errorMessage = L.s.configureApiKey
            return
        }

        isLoadingAnalysis = true
        errorMessage = nil
        defer { isLoadingAnalysis = false }

        do {
            analysis = try await llmService.analyze(repo: repo, readme: readme, settings: settings)
        } catch {
            errorMessage = "\(L.s.analyzeFailed): \(error.localizedDescription)"
        }
    }

    func fetchRepoActivity(repo: StarredRepo, settings: AppSettings) async {
        isLoadingActivity = true
        defer { isLoadingActivity = false }

        do {
            async let tags = githubService.fetchRecentTags(
                owner: repo.owner.login, repo: repo.name, settings: settings
            )
            async let commits = githubService.fetchRecentCommits(
                owner: repo.owner.login, repo: repo.name, settings: settings
            )
            async let releases = githubService.fetchRecentReleases(
                owner: repo.owner.login, repo: repo.name, settings: settings
            )
            let (fetchedTags, fetchedCommits, fetchedReleases) = try await (tags, commits, releases)

            let tagShas = Set(fetchedTags.map(\.commit.sha))
            recentCommits = fetchedCommits.map { commit in
                var c = commit
                return c
            }
            recentTags = fetchedTags
            recentReleases = fetchedReleases
        } catch {}
    }
}
