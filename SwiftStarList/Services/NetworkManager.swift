import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case unauthorized
    case httpError(Int, String)
    case decodingError(Error)
    case noData
    case proxyConnectionFailed

    var errorDescription: String? {
        let s = L.s
        switch self {
        case .invalidURL: return s.invalidURL
        case .unauthorized: return s.unauthorized
        case .httpError(let code, let msg): return "\(s.httpError) \(code): \(msg)"
        case .decodingError(let e): return "\(s.decodingError): \(e.localizedDescription)"
        case .noData: return s.noData
        case .proxyConnectionFailed: return s.proxyConnectionFailed
        }
    }
}

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    func request<T: Decodable>(_ url: String, settings: AppSettings, accept: String = "application/vnd.github+json") async throws -> T {
        guard let url = URL(string: url) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(settings.githubToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")

        let session = makeSession(proxyConfig: settings.githubProxyConfig)
        let (data, response) = try await session.data(for: request)

        try checkResponse(response, data: data)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    func requestWithPagination<T: Decodable>(_ url: String, settings: AppSettings, accept: String = "application/vnd.github+json") async throws -> (T, Bool) {
        guard let url = URL(string: url) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(settings.githubToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")

        let session = makeSession(proxyConfig: settings.githubProxyConfig)
        let (data, response) = try await session.data(for: request)

        try checkResponse(response, data: data)

        let decoded: T
        do {
            decoded = try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }

        let hasNextPage: Bool
        if let httpResponse = response as? HTTPURLResponse,
           let linkHeader = httpResponse.value(forHTTPHeaderField: "Link") {
            hasNextPage = linkHeader.contains("rel=\"next\"")
        } else {
            hasNextPage = false
        }

        return (decoded, hasNextPage)
    }

    func requestRaw(_ url: String, settings: AppSettings) async throws -> Data {
        guard let url = URL(string: url) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.object", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(settings.githubToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")

        let session = makeSession(proxyConfig: settings.githubProxyConfig)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data)
        return data
    }

    func postJSON<T: Decodable>(_ url: String, body: Encodable, apiKey: String, proxyConfig: ProxyConfig) async throws -> T {
        guard let url = URL(string: url) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)

        let session = makeSession(proxyConfig: proxyConfig)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    private func makeSession(proxyConfig: ProxyConfig) -> URLSession {
        switch proxyConfig.mode {
        case .none:
            return URLSession.shared
        case .system:
            return URLSession(configuration: .default)
        case .http, .socks:
            let config = URLSessionConfiguration.default
            let proxy = proxyConfig.mode == .http
                ? ["HTTPProxy": "\(proxyConfig.host):\(proxyConfig.port)"]
                : ["SOCKSProxy": "\(proxyConfig.host):\(proxyConfig.port)"]
            config.connectionProxyDictionary = proxy
            return URLSession(configuration: config)
        }
    }

    private func checkResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        if httpResponse.statusCode == 401 { throw NetworkError.unauthorized }
        if !(200...299).contains(httpResponse.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NetworkError.httpError(httpResponse.statusCode, body)
        }
    }
}
