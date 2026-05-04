import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var showToken = false

    var body: some View {
        Form {
            Section("GitHub") {
                HStack {
                    if showToken {
                        TextField("GitHub Token", text: $settingsManager.settings.githubToken)
                    } else {
                        SecureField("GitHub Token", text: $settingsManager.settings.githubToken)
                    }
                    Button(action: { showToken.toggle() }) {
                        Image(systemName: showToken ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }

                ProxyConfigSection(config: $settingsManager.settings.githubProxyConfig)
            }

            Section("LLM 设置") {
                TextField("Base URL", text: $settingsManager.settings.llmConfig.baseURL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                SecureField("API Key", text: $settingsManager.settings.llmConfig.apiKey)
                TextField("Model", text: $settingsManager.settings.llmConfig.model)
                    .autocorrectionDisabled()

                ProxyConfigSection(config: $settingsManager.settings.llmConfig.proxyConfig)

                Toggle("点击AI分析时自动开始", isOn: $settingsManager.settings.autoAnalyze)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 500, minHeight: 500)
    }
}

struct ProxyConfigSection: View {
    @Binding var config: ProxyConfig

    var body: some View {
        Group {
            Picker("代理模式", selection: $config.mode) {
                ForEach(ProxyMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            if config.mode == .http || config.mode == .socks {
                TextField("主机地址", text: $config.host)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                TextField("端口", value: $config.port, format: .number)
            }
        }
    }
}
