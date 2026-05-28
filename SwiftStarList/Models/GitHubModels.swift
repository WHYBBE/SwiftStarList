import Foundation

struct StarredRepoEnvelope: Codable {
    let starredAt: String
    let repo: StarredRepo

    enum CodingKeys: String, CodingKey {
        case starredAt = "starred_at"
        case repo
    }
}

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
    let pushedAt: String?
    let fork: Bool
    let homepage: String?
    var starredAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, owner, description, language, topics, fork, homepage, starredAt
        case fullName = "full_name"
        case htmlUrl = "html_url"
        case stargazersCount = "stargazers_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case pushedAt = "pushed_at"
    }

    static func == (lhs: StarredRepo, rhs: StarredRepo) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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

struct RepoTag: Codable, Identifiable {
    let name: String
    let commit: TagCommit

    var id: String { name }
}

struct TagCommit: Codable {
    let sha: String
    let url: String?
}

struct RepoCommit: Codable, Identifiable {
    let sha: String
    let htmlUrl: String?
    let commit: CommitDetail
    let author: CommitAuthorInfo?

    var id: String { sha }

    enum CodingKeys: String, CodingKey {
        case sha, commit, author
        case htmlUrl = "html_url"
    }
}

struct CommitDetail: Codable {
    let author: CommitUser?
    let committer: CommitUser?
    let message: String
}

struct CommitUser: Codable {
    let name: String?
    let email: String?
    let date: String?
}

struct CommitAuthorInfo: Codable {
    let login: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
    }
}

struct RepoRelease: Codable, Identifiable {
    let id: Int
    let tagName: String
    let name: String?
    let body: String?
    let draft: Bool
    let prerelease: Bool
    let createdAt: String
    let publishedAt: String?
    let htmlUrl: String
    let author: ReleaseAuthorInfo?

    enum CodingKeys: String, CodingKey {
        case id, name, body, draft, prerelease, author
        case tagName = "tag_name"
        case createdAt = "created_at"
        case publishedAt = "published_at"
        case htmlUrl = "html_url"
    }
}

struct ReleaseAuthorInfo: Codable {
    let login: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
    }
}
