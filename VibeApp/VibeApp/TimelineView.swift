import SwiftUI
import UIKit

struct TimelineView: View {
    @EnvironmentObject private var store: ScreenshotStore
    @State private var searchText = ""
    @State private var selectedTag = "全部"
    let title: String

    init(title: String = "历史") {
        self.title = title
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Picker("标签", selection: $selectedTag) {
                    ForEach(availableTags, id: \.self) { tag in
                        Text(tag).tag(tag)
                    }
                }
                .pickerStyle(.segmented)

                if filteredItems.isEmpty {
                    ContentUnavailableView("暂无历史", systemImage: "tray", description: Text("在首页导入截图后，这里会按时间展示。"))
                } else {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(filteredItems) { item in
                            NavigationLink(destination: CardDetailView(item: item)) {
                                CardRowView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: filteredItems.count)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "搜索内容或标签")
    }

    private var availableTags: [String] {
        let tags = store.items.flatMap { $0.tags }
        let unique = Array(Set(tags)).sorted()
        return ["全部"] + unique
    }

    private var filteredItems: [ScreenshotItem] {
        store.items.filter { item in
            let matchesTag = selectedTag == "全部" || item.tags.contains(selectedTag)
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                matchesSearch =
                    item.ocrText.localizedCaseInsensitiveContains(searchText) ||
                    item.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) ||
                    (item.summary?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
            return matchesTag && matchesSearch
        }
    }
}

struct CardRowView: View {
    let item: ScreenshotItem

    private var thumbnail: Image? {
        guard let path = item.imageLocalPath,
              let uiImage = UIImage(contentsOfFile: path) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            if let thumbnail {
                thumbnail
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 128)
                    .clipped()
                    .cornerRadius(DesignTokens.Radius.sm)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(item.summary?.isEmpty == false ? item.summary! : item.ocrText)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                if !item.tags.isEmpty {
                    Text(item.tags.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: DesignTokens.Sizes.listRowMinHeight, alignment: .leading)
        .glassCard()
    }
}
