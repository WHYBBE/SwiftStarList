import AppKit
import SwiftUI

enum AppLanguage: String, CaseIterable, Codable {
    case system = "system"
    case zh = "zh"
    case en = "en"

    var displayName: String {
        switch self {
        case .system: return L.s.systemLanguage
        case .zh: return "中文"
        case .en: return "English"
        }
    }

    var locale: Locale {
        switch self {
        case .system: return Locale.current
        case .zh: return Locale(identifier: "zh_CN")
        case .en: return Locale(identifier: "en_US")
        }
    }
}

enum AppTheme: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return L.s.systemTheme
        case .light: return L.s.lightTheme
        case .dark: return L.s.darkTheme
        }
    }

    var appearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .system: return Self.systemColorScheme
        case .light: return .light
        case .dark: return .dark
        }
    }

    private static var systemColorScheme: ColorScheme {
        let saved = NSApp.appearance
        NSApp.appearance = nil
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        NSApp.appearance = saved
        return isDark ? .dark : .light
    }
}

enum ProxyMode: String, CaseIterable, Codable {
    case none = "none"
    case system = "system"
    case http = "http"
    case socks = "socks5"

    var displayName: String {
        switch self {
        case .none: return L.s.proxyNone
        case .system: return L.s.proxySystem
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
    var language: AppLanguage
    var theme: AppTheme

    static let `default` = AppSettings(
        githubToken: "",
        githubProxyConfig: .default,
        llmConfig: .default,
        autoAnalyze: false,
        language: .system,
        theme: .system
    )
}
