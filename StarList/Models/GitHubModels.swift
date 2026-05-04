import Foundation

struct StarredRepo: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let fullName: String
    let owner: RepoOwner
    let htmlUrl: String
    let description: String?
    let stargazersCount: Int
    let language: String?
    let topics: [String]
    let createdAt: String
    let updatedAt: String
    let fork: Bool
    let homepage: String?

    enum CodingKeys: String, CodingKey {
        case id, name, owner, description, language, topics, fork, homepage
        case fullName = "full_name"
        case htmlUrl = "html_url"
        case stargazersCount = "stargazers_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RepoOwner: Codable, Hashable {
    let login: String
    let avatarUrl: String

    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
    }
}

struct READMEContent: Codable {
    let content: String?
    let encoding: String?
    let name: String
    let path: String
}
