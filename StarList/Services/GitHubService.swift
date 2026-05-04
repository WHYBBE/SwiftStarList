import Foundation

actor GitHubService {
    private let network = NetworkManager.shared

    func fetchStarredRepos(page: Int = 1, perPage: Int = 100, settings: AppSettings) async throws -> [StarredRepo] {
        let url = "https://api.github.com/user/starred?per_page=\(perPage)&page=\(page)"
        return try await network.request(url, settings: settings)
    }

    func fetchREADME(owner: String, repo: String, settings: AppSettings) async throws -> String {
        let url = "https://api.github.com/repos/\(owner)/\(repo)/contents/README.md"
        let data = try await network.requestRaw(url, settings: settings)
        let readme = try JSONDecoder().decode(READMEContent.self, from: data)
        guard let content = readme.content, readme.encoding == "base64" else {
            return "无法读取README内容"
        }
        let cleaned = content.replacingOccurrences(of: "\n", with: "")
        guard let decodedData = Data(base64Encoded: cleaned) else {
            return "Base64解码失败"
        }
        return String(data: decodedData, encoding: .utf8) ?? "编码转换失败"
    }
}
