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

    func reset() {
        readmeContent = nil
        analysis = nil
        errorMessage = nil
        isLoadingREADME = false
        isLoadingAnalysis = false
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
            readmeContent = "获取README失败: \(error.localizedDescription)"
        }
    }

    func analyzeRepo(repo: StarredRepo, settings: AppSettings) async {
        if readmeContent == nil {
            await fetchREADME(repo: repo, settings: settings)
        }

        guard let readme = readmeContent, !readme.hasPrefix("获取README失败") else {
            errorMessage = "无法获取README，请先确保README加载成功"
            return
        }

        guard !settings.llmConfig.apiKey.isEmpty else {
            errorMessage = "请先配置LLM API Key"
            return
        }

        isLoadingAnalysis = true
        errorMessage = nil
        defer { isLoadingAnalysis = false }

        do {
            analysis = try await llmService.analyze(repo: repo, readme: readme, settings: settings)
        } catch {
            errorMessage = "LLM分析失败: \(error.localizedDescription)"
        }
    }
}
