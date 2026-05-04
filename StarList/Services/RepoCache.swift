import Foundation

final class RepoCache {
    static let shared = RepoCache()
    private let cacheDirectory: URL
    private let reposFile: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        cacheDirectory = appSupport.appendingPathComponent("StarList", isDirectory: true)
        reposFile = cacheDirectory.appendingPathComponent("starred_repos.json")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func save(_ repos: [StarredRepo]) {
        do {
            let data = try encoder.encode(repos)
            try data.write(to: reposFile, options: .atomic)
        } catch {
            print("Cache save error: \(error)")
        }
    }

    func load() -> [StarredRepo]? {
        guard FileManager.default.fileExists(atPath: reposFile.path) else { return nil }
        do {
            let data = try Data(contentsOf: reposFile)
            return try decoder.decode([StarredRepo].self, from: data)
        } catch {
            print("Cache load error: \(error)")
            return nil
        }
    }

    func clear() {
        try? FileManager.default.removeItem(at: reposFile)
    }
}
