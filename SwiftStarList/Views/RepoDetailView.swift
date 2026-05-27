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
            mainContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: repo.id) {
            showReadme = true
            showAnalysis = false
            viewModel.reset()
            await viewModel.fetchREADME(repo: repo, settings: settingsManager.settings)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AsyncImage(url: URL(string: repo.owner.avatarUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color(nsColor: .placeholderTextColor).opacity(0.3)
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())

                Text(repo.fullName)
                    .font(.title2.bold())

                Spacer()

                if let url = URL(string: repo.htmlUrl) {
                    Link(destination: url) {
                        Label(L.s.openInGithub, systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.bordered)
                    .id(settingsManager.languageVersion)
                }
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
                                    .foregroundColor(.link)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                TabButton(title: L.s.readmeTab, icon: "doc.text", isSelected: showReadme && !showAnalysis, selectedColor: .accentColor) {
                    showReadme = true; showAnalysis = false
                }
                .id(settingsManager.languageVersion)

                TabButton(title: L.s.aiTab, icon: "sparkles", isSelected: showAnalysis, selectedColor: .purple) {
                    showAnalysis = true; showReadme = false
                    if settingsManager.settings.autoAnalyze && viewModel.analysis == nil {
                        Task {
                            await viewModel.analyzeRepo(repo: repo, settings: settingsManager.settings)
                        }
                    }
                }
                .id(settingsManager.languageVersion)
            }
        }
        .padding()
    }

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if showReadme {
                    readmeView
                } else {
                    analysisView
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var readmeView: some View {
        if viewModel.isLoadingREADME {
            VStack(spacing: 12) {
                ProgressView()
                Text(L.s.loadingReadme)
                    .foregroundColor(.secondary)
                    .id(settingsManager.languageVersion)
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
                Text(L.s.analyzing)
                    .foregroundColor(.secondary)
                    .id(settingsManager.languageVersion)
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
                Text(L.s.analyzeRepo)
                    .foregroundColor(.secondary)
                    .id(settingsManager.languageVersion)
                Button(L.s.startAnalysis) {
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

private struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? selectedColor : Color(nsColor: .controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .secondary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
