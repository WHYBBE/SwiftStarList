import Foundation

actor LLMService {
    private let network = NetworkManager.shared

    func analyze(repo: StarredRepo, readme: String, settings: AppSettings) async throws -> String {
        let prompt = """
        请分析以下GitHub仓库并提供总结：

        仓库名称：\(repo.fullName)
        描述：\(repo.description ?? "无")
        主要语言：\(repo.language ?? "未知")
        Star数：\(repo.stargazersCount)
        Topics：\(repo.topics.joined(separator: ", "))

        README内容：
        \(readme.prefix(8000))

        请从以下几个方面进行分析：
        1. 项目简介（一句话概括）
        2. 核心功能
        3. 技术栈
        4. 适用场景
        5. 活跃度评估
        """

        let request = ChatCompletionRequest(
            model: settings.llmConfig.model,
            messages: [
                ChatMessage(role: "system", content: "你是一个专业的GitHub仓库分析助手，请用中文简洁地分析仓库。"),
                ChatMessage(role: "user", content: prompt)
            ],
            temperature: 0.3
        )

        let baseURL = settings.llmConfig.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let path = baseURL.hasSuffix("/v1") ? "chat/completions" : "v1/chat/completions"
        let url = "\(baseURL)/\(path)"
        let response: ChatCompletionResponse = try await network.postJSON(url, body: request, apiKey: settings.llmConfig.apiKey, proxyConfig: settings.llmConfig.proxyConfig)
        guard let choice = response.choices.first else {
            return "LLM未返回有效响应"
        }
        return choice.message.content
    }
}
