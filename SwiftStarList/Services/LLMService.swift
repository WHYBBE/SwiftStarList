import Foundation

actor LLMService {
    private let network = NetworkManager.shared

    func analyze(repo: StarredRepo, readme: String, settings: AppSettings) async throws -> String {
        let s = L.s
        let prompt: String
        let systemMessage: String

        let isZh: Bool
        switch settings.language {
        case .system:
            isZh = Locale.current.language.languageCode?.identifier == "zh"
        case .zh:
            isZh = true
        case .en:
            isZh = false
        }

        if isZh {
            prompt = """
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
            systemMessage = "你是一个专业的GitHub仓库分析助手，请用中文简洁地分析仓库。"
        } else {
            prompt = """
            Please analyze the following GitHub repository and provide a summary:

            Repository: \(repo.fullName)
            Description: \(repo.description ?? "None")
            Language: \(repo.language ?? "Unknown")
            Stars: \(repo.stargazersCount)
            Topics: \(repo.topics.joined(separator: ", "))

            README content:
            \(readme.prefix(8000))

            Please analyze from the following aspects:
            1. Brief summary (one sentence)
            2. Core features
            3. Tech stack
            4. Use cases
            5. Activity assessment
            """
            systemMessage = "You are a professional GitHub repository analysis assistant. Provide concise analysis in English."
        }

        let request = ChatCompletionRequest(
            model: settings.llmConfig.model,
            messages: [
                ChatMessage(role: "system", content: systemMessage),
                ChatMessage(role: "user", content: prompt)
            ],
            temperature: 0.3
        )

        let baseURL = settings.llmConfig.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let path = baseURL.hasSuffix("/v1") ? "chat/completions" : "v1/chat/completions"
        let url = "\(baseURL)/\(path)"
        let response: ChatCompletionResponse = try await network.postJSON(url, body: request, apiKey: settings.llmConfig.apiKey, proxyConfig: settings.llmConfig.proxyConfig)
        guard let choice = response.choices.first else {
            return s.llmNoResponse
        }
        return choice.message.content
    }
}
