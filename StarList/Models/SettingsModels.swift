import Foundation

enum ProxyMode: String, CaseIterable, Codable {
    case none = "none"
    case system = "system"
    case http = "http"
    case socks = "socks5"

    var displayName: String {
        switch self {
        case .none: return "无"
        case .system: return "系统代理"
        case .http: return "HTTP"
        case .socks: return "SOCKS5"
        }
    }
}

struct ProxyConfig: Codable {
    var mode: ProxyMode
    var host: String
    var port: Int

    static let `default` = ProxyConfig(mode: .none, host: "127.0.0.1", port: 7890)
}

struct LLMConfig: Codable {
    var baseURL: String
    var apiKey: String
    var model: String
    var proxyConfig: ProxyConfig

    static let `default` = LLMConfig(baseURL: "https://api.openai.com", apiKey: "", model: "gpt-4o-mini", proxyConfig: .default)
}

struct AppSettings: Codable {
    var githubToken: String
    var githubProxyConfig: ProxyConfig
    var llmConfig: LLMConfig
    var autoAnalyze: Bool

    static let `default` = AppSettings(
        githubToken: "",
        githubProxyConfig: .default,
        llmConfig: .default,
        autoAnalyze: false
    )
}
