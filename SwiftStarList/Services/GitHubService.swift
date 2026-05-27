import Foundation

actor GitHubService {
    private let network = NetworkManager.shared

    func fetchAllStarredRepos(settings: AppSettings) async throws -> [StarredRepo] {
        var allRepos: [StarredRepo] = []
        var page = 1
        let perPage = 100

        while true {
            let url = "https://api.github.com/user/starred?per_page=\(perPage)&page=\(page)&sort=created&direction=desc"
            let (envelopes, hasNextPage) = try await network.requestWithPagination(
                url, settings: settings, accept: "application/vnd.github.star+json"
            ) as ([StarredRepoEnvelope], Bool)
            let repos = envelopes.map { envelope in
                var repo = envelope.repo
                repo.starredAt = envelope.starredAt
                return repo
            }
            allRepos.append(contentsOf: repos)
            if !hasNextPage { break }
            page += 1
        }
        return allRepos
    }

    func fetchREADME(owner: String, repo: String, settings: AppSettings) async throws -> String {
        let url = "https://api.github.com/repos/\(owner)/\(repo)/contents/README.md"
        let data = try await network.requestRaw(url, settings: settings)
        let readme = try JSONDecoder().decode(READMEContent.self, from: data)
        guard let content = readme.content, readme.encoding == "base64" else {
            return L.s.cannotReadReadme
        }
        let cleaned = content.replacingOccurrences(of: "\n", with: "")
        guard let decodedData = Data(base64Encoded: cleaned) else {
            return L.s.base64Failed
        }
        return String(data: decodedData, encoding: .utf8) ?? L.s.encodingFailed
    }
}
