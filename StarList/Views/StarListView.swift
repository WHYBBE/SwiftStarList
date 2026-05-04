import SwiftUI

struct StarListView: View {
    @ObservedObject var settingsManager: SettingsManager
    @StateObject private var viewModel = StarListViewModel()
    @State private var selectedRepo: StarredRepo?

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                SearchBar(text: $viewModel.searchText)
                    .padding(8)

                filterBar

                if viewModel.isLoading && viewModel.repos.isEmpty {
                    Spacer()
                    ProgressView("加载中...")
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("加载失败").font(.headline)
                        Text(error).font(.caption).foregroundColor(.secondary)
                        Button("重试") {
                            Task { await viewModel.fetchAll(settings: settingsManager.settings) }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    Spacer()
                } else {
                    repoList
                }
            }
            .navigationTitle("Star 列表")
            .navigationSplitViewColumnWidth(min: 260, ideal: 300)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 8) {
                        if viewModel.isFromCache {
                            Text("缓存")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if viewModel.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Button(action: {
                            Task { await viewModel.fetchAll(settings: settingsManager.settings) }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .task {
                viewModel.loadFromCache()
                if viewModel.repos.isEmpty {
                    await viewModel.fetchAll(settings: settingsManager.settings)
                }
            }
        } detail: {
            if let repo = selectedRepo {
                RepoDetailView(repo: repo, settingsManager: settingsManager)
            } else {
                Text("选择一个仓库查看详情")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundColor(.secondary)
            }
        }
        .navigationSplitViewStyle(.automatic)
    }

    private var filterBar: some View {
        HStack(spacing: 6) {
            Picker("排序", selection: $viewModel.sortOption) {
                ForEach(SortOption.allCases, id: \.self) { opt in
                    Text(opt.displayName).tag(opt)
                }
            }
            .labelsHidden()

            Picker("分组", selection: $viewModel.groupOption) {
                ForEach(GroupOption.allCases, id: \.self) { opt in
                    Text(opt.displayName).tag(opt)
                }
            }
            .labelsHidden()

            Spacer()

            Text("\(viewModel.filteredRepos.count) 个仓库")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private var repoList: some View {
        List(selection: $selectedRepo) {
            ForEach(viewModel.groupedRepos, id: \.0) { group in
                if viewModel.groupOption != .none {
                    Section(group.0) {
                        ForEach(group.1) { repo in
                            StarRowView(repo: repo)
                                .tag(repo)
                        }
                    }
                } else {
                    ForEach(group.1) { repo in
                        StarRowView(repo: repo)
                            .tag(repo)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索仓库...", text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct StarRowView: View {
    let repo: StarredRepo

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AsyncImage(url: URL(string: repo.owner.avatarUrl)) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(repo.fullName)
                    .font(.system(size: 13, weight: .medium))
                if let desc = repo.description {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 8) {
                    if let lang = repo.language {
                        LanguageTag(language: lang)
                    }
                    Label("\(repo.stargazersCount)", systemImage: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    if let starredAt = repo.starredAt {
                        Text(starredAt.prefix(10))
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct LanguageTag: View {
    let language: String

    var body: some View {
        Text(language)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(languageColor.opacity(0.15))
            .foregroundColor(languageColor)
            .cornerRadius(4)
    }

    private var languageColor: Color {
        switch language {
        case "Swift": return .orange
        case "Python": return .blue
        case "JavaScript": return .yellow
        case "TypeScript": return .blue
        case "Rust": return .red
        case "Go": return .cyan
        case "Java": return .red
        case "C++": return .purple
        case "C": return .purple
        case "Ruby": return .red
        case "Kotlin": return .purple
        case "Shell": return .green
        case "Dart": return .cyan
        case "PHP": return .purple
        case "C#": return .purple
        case "Objective-C": return .orange
        case "HTML": return .orange
        case "CSS": return .purple
        case "Vue": return .green
        default: return .gray
        }
    }
}
