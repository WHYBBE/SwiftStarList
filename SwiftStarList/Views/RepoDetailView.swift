import SwiftUI
import MarkdownUI

struct RepoDetailView: View {
    let repo: StarredRepo
    @ObservedObject var settingsManager: SettingsManager
    @StateObject private var viewModel = RepoDetailViewModel()
    @State private var showReadme = true
    @State private var showAnalysis = false
    @State private var showActivity = false

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
            showActivity = false
            viewModel.reset()
            async let readmeTask: Void = viewModel.fetchREADME(repo: repo, settings: settingsManager.settings)
            async let activityTask: Void = viewModel.fetchRepoActivity(repo: repo, settings: settingsManager.settings)
            _ = try? await (readmeTask, activityTask)
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
                TabButton(title: L.s.readmeTab, icon: "doc.text", isSelected: showReadme && !showAnalysis && !showActivity, selectedColor: .accentColor) {
                    showReadme = true; showAnalysis = false; showActivity = false
                }
                .id(settingsManager.languageVersion)

                TabButton(title: L.s.activityTab, icon: "chart.bar", isSelected: showActivity, selectedColor: .green) {
                    showActivity = true; showReadme = false; showAnalysis = false
                }
                .id(settingsManager.languageVersion)

                TabButton(title: L.s.aiTab, icon: "sparkles", isSelected: showAnalysis, selectedColor: .purple) {
                    showAnalysis = true; showReadme = false; showActivity = false
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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading) {
                    if showReadme {
                        readmeView
                    } else if showActivity {
                        activityView(proxy: proxy)
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
    private func activityView(proxy: ScrollViewProxy) -> some View {
        if viewModel.isLoadingActivity {
            VStack(spacing: 12) {
                ProgressView()
                Text(L.s.loadingActivity)
                    .foregroundColor(.secondary)
                    .id(settingsManager.languageVersion)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else {
            VStack(alignment: .leading, spacing: 20) {
                tagsSection(proxy: proxy)
                releasesSection
                commitsSection
            }
        }
    }

    @ViewBuilder
    private var releasesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.s.recentReleases)
                .font(.title3.bold())
                .id(settingsManager.languageVersion)

            if viewModel.recentReleases.isEmpty {
                Text(L.s.noReleases)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .id(settingsManager.languageVersion)
            } else {
                ForEach(viewModel.recentReleases) { release in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            if let url = URL(string: repo.htmlUrl) {
                                Link(destination: url.appendingPathComponent("releases/tag/\(release.tagName)")) {
                                    Text(release.tagName)
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            } else {
                                Text(release.tagName)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            if release.draft {
                                Text(L.s.draftBadge)
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .foregroundColor(.orange)
                                    .cornerRadius(4)
                            }
                            if release.prerelease {
                                Text(L.s.prereleaseBadge)
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.purple.opacity(0.2))
                                    .foregroundColor(.purple)
                                    .cornerRadius(4)
                            }
                            Spacer()
                            if let published = release.publishedAt {
                                Text(published.prefix(10))
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        if let name = release.name, name != release.tagName {
                            Text(name)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        if let author = release.author, let login = author.login {
                            HStack(spacing: 4) {
                                Text(login)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let body = release.body, !body.isEmpty {
                            let lines = body.split(separator: "\n", omittingEmptySubsequences: true)
                            let preview = lines.prefix(8).joined(separator: "\n")
                            VStack(alignment: .leading, spacing: 2) {
                                Markdown(preview)
                                    .markdownTheme(.transparent)
                                    .tint(.link)
                                    .font(.system(size: 12))
                                if lines.count > 8 {
                                    Text("...")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .id("release-\(release.tagName)")
                }
            }
        }
    }

    @ViewBuilder
    private func tagsSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.s.recentTags)
                .font(.title3.bold())
                .id(settingsManager.languageVersion)

            if viewModel.recentTags.isEmpty {
                Text(L.s.noTags)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .id(settingsManager.languageVersion)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(viewModel.recentTags) { tag in
                        let hasRelease = viewModel.recentReleases.contains { $0.tagName == tag.name }
                        Button {
                            if hasRelease {
                                withAnimation {
                                    proxy.scrollTo("release-\(tag.name)", anchor: .top)
                                }
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Text(tag.name)
                                if hasRelease {
                                    Image(systemName: "arrow.up.right.circle.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(.green)
                                }
                            }
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var commitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.s.recentCommits)
                .font(.title3.bold())
                .id(settingsManager.languageVersion)

            if viewModel.recentCommits.isEmpty {
                Text(L.s.noCommits)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .id(settingsManager.languageVersion)
            } else {
                ForEach(viewModel.recentCommits) { commit in
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(commit.commit.message.split(separator: "\n").first.map(String.init) ?? "")
                                .font(.system(size: 12))
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                if let login = commit.author?.login {
                                    Text(login)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                if let date = commit.commit.author?.date {
                                    Text(date.prefix(10))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        Spacer()
                        if let url = URL(string: repo.htmlUrl) {
                            Link(destination: url.appendingPathComponent("commit/\(commit.sha)")) {
                                Text(commit.sha.prefix(7))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
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

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
