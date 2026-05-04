import SwiftUI
import MarkdownUI

struct RepoDetailView: View {
    let repo: StarredRepo
    @ObservedObject var settingsManager: SettingsManager
    @StateObject private var viewModel = RepoDetailViewModel()
    @State private var showReadme = true
    @State private var showAnalysis = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection

            Divider()

            HStack(spacing: 0) {
                sidebar
                Divider()
                mainContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.fetchREADME(repo: repo, settings: settingsManager.settings)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AsyncImage(url: URL(string: repo.owner.avatarUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())

                Text(repo.fullName)
                    .font(.title2.bold())

                Spacer()

                Link(destination: URL(string: repo.htmlUrl)!) {
                    Label("在GitHub中打开", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
            }

            if let desc = repo.description {
                Text(desc)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                if let lang = repo.language {
                    LanguageTag(language: lang)
                }
                Label("\(repo.stargazersCount)", systemImage: "star.fill")
                    .foregroundColor(.orange)
                if !repo.topics.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(repo.topics, id: \.self) { topic in
                                Text("#\(topic)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: { showReadme = true; showAnalysis = false }) {
                Label("README", systemImage: "doc.text")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .tint(showReadme && !showAnalysis ? .accentColor : .clear)
            .foregroundColor(showReadme && !showAnalysis ? .white : .primary)

            Button(action: { showAnalysis = true; showReadme = false }) {
                Label("AI 分析", systemImage: "sparkles")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .tint(showAnalysis ? .purple : .clear)
            .foregroundColor(showAnalysis ? .white : .primary)

            Spacer()
        }
        .padding(12)
        .frame(width: 160)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var mainContent: some View {
        ScrollView {
            if showReadme {
                readmeView
            } else {
                analysisView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private var readmeView: some View {
        if viewModel.isLoadingREADME {
            VStack(spacing: 12) {
                ProgressView()
                Text("加载README...")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else if let content = viewModel.readmeContent {
            Markdown(content)
                .markdownTheme(.transparent)
                .tint(.accentColor)
        }
    }

    @ViewBuilder
    private var analysisView: some View {
        if let error = viewModel.errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text(error)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else if viewModel.isLoadingAnalysis {
            VStack(spacing: 12) {
                ProgressView()
                Text("AI 正在分析...")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else if let analysis = viewModel.analysis {
            Markdown(analysis)
                .markdownTheme(.transparent)
                .tint(.purple)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundColor(.purple)
                Text("点击下方按钮让AI分析此仓库")
                    .foregroundColor(.secondary)
                Button("开始分析") {
                    Task {
                        await viewModel.analyzeRepo(repo: repo, settings: settingsManager.settings)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        }
    }
}

extension Theme {
    static let transparent = Theme()
        .text {
            ForegroundColor(.primary)
            FontSize(16)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.85))
            BackgroundColor(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
        .strong {
            FontWeight(.semibold)
        }
        .link {
            ForegroundColor(.link)
        }
        .heading1 { configuration in
            VStack(alignment: .leading, spacing: 0) {
                configuration.label
                    .relativePadding(.bottom, length: .em(0.3))
                    .relativeLineSpacing(.em(0.125))
                    .markdownMargin(top: 24, bottom: 16)
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(.em(2))
                    }
                Divider()
            }
        }
        .heading2 { configuration in
            VStack(alignment: .leading, spacing: 0) {
                configuration.label
                    .relativePadding(.bottom, length: .em(0.3))
                    .relativeLineSpacing(.em(0.125))
                    .markdownMargin(top: 24, bottom: 16)
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(.em(1.5))
                    }
                Divider()
            }
        }
        .heading3 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 24, bottom: 16)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.25))
                }
        }
        .heading4 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 24, bottom: 16)
                .markdownTextStyle {
                    FontWeight(.semibold)
                }
        }
        .heading5 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 24, bottom: 16)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(0.875))
                }
        }
        .heading6 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 24, bottom: 16)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(0.85))
                    ForegroundColor(.secondary)
                }
        }
        .paragraph { configuration in
            configuration.label
                .fixedSize(horizontal: false, vertical: true)
                .relativeLineSpacing(.em(0.25))
                .markdownMargin(top: 0, bottom: 16)
        }
        .blockquote { configuration in
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.3))
                    .relativeFrame(width: .em(0.2))
                configuration.label
                    .markdownTextStyle { ForegroundColor(.secondary) }
                    .relativePadding(.horizontal, length: .em(1))
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .codeBlock { configuration in
            ScrollView(.horizontal) {
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .relativeLineSpacing(.em(0.225))
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                    }
                    .padding(16)
            }
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .markdownMargin(top: 0, bottom: 16)
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: .em(0.25))
        }
        .taskListMarker { configuration in
            Image(systemName: configuration.isCompleted ? "checkmark.square.fill" : "square")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .imageScale(.small)
                .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
        }
        .table { configuration in
            configuration.label
                .fixedSize(horizontal: false, vertical: true)
                .markdownTableBorderStyle(.init(color: .secondary.opacity(0.3)))
                .markdownTableBackgroundStyle(
                    .alternatingRows(Color.clear, Color(nsColor: .controlBackgroundColor).opacity(0.3))
                )
                .markdownMargin(top: 0, bottom: 16)
        }
        .tableCell { configuration in
            configuration.label
                .markdownTextStyle {
                    if configuration.row == 0 {
                        FontWeight(.semibold)
                    }
                    BackgroundColor(nil)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 6)
                .padding(.horizontal, 13)
                .relativeLineSpacing(.em(0.25))
        }
        .thematicBreak {
            Divider()
                .relativeFrame(height: .em(0.25))
                .markdownMargin(top: 24, bottom: 24)
        }
}

private extension Color {
    static let link = Color(
        light: Color(rgba: 0x2c65_cfff),
        dark: Color(rgba: 0x4c8e_f8ff)
    )
}
