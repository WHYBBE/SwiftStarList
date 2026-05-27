import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var showToken = false

    var body: some View {
        Form {
            Section(L.s.languageSection) {
                Picker(L.s.languageSection, selection: $settingsManager.settings.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
            }

            Section(L.s.themeSection) {
                Picker(L.s.themeSection, selection: $settingsManager.settings.theme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            }

            Section(L.s.githubSection) {
                HStack {
                    if showToken {
                        TextField(L.s.githubToken, text: $settingsManager.settings.githubToken)
                    } else {
                        SecureField(L.s.githubToken, text: $settingsManager.settings.githubToken)
                    }
                    Button(action: { showToken.toggle() }) {
                        Image(systemName: showToken ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }

                ProxyConfigSection(config: $settingsManager.settings.githubProxyConfig)
            }

            Section(L.s.llmSection) {
                TextField(L.s.baseURL, text: $settingsManager.settings.llmConfig.baseURL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                SecureField(L.s.apiKey, text: $settingsManager.settings.llmConfig.apiKey)
                TextField(L.s.model, text: $settingsManager.settings.llmConfig.model)
                    .autocorrectionDisabled()

                ProxyConfigSection(config: $settingsManager.settings.llmConfig.proxyConfig)

                Toggle(L.s.autoAnalyze, isOn: $settingsManager.settings.autoAnalyze)
            }
        }
        .formStyle(.grouped)
        .id(settingsManager.languageVersion)
        .frame(minWidth: 500, minHeight: 500)
        .onDisappear {
            settingsManager.isSettingsOpen = false
            if settingsManager.settings.theme == .system {
                NSApp.appearance = nil
                for window in NSApp.windows {
                    window.appearance = nil
                }
            }
        }
        .onAppear {
            settingsManager.isSettingsOpen = true
        }
    }
}

struct ProxyConfigSection: View {
    @Binding var config: ProxyConfig

    var body: some View {
        Group {
            Picker(L.s.proxyMode, selection: $config.mode) {
                ForEach(ProxyMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            if config.mode == .http || config.mode == .socks {
                TextField(L.s.host, text: $config.host)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                TextField(L.s.port, value: $config.port, format: .number)
            }
        }
    }
}
