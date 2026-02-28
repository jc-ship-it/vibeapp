import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var store: ScreenshotStore
    @State private var searchText = ""
    @State private var selectedTag = "全部"

    var body: some View {
        VStack(spacing: 8) {
            Picker("标签", selection: $selectedTag) {
                ForEach(availableTags, id: \.self) { tag in
                    Text(tag).tag(tag)
                }
            }
            .pickerStyle(.segmented)

            if filteredItems.isEmpty {
                ContentUnavailableView("暂无卡片", systemImage: "tray", description: Text("导入截图后自动生成卡片"))
            } else {
                List {
                    ForEach(filteredItems) { item in
                        NavigationLink(destination: CardDetailView(item: item)) {
                            CardRowView(item: item)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("时间线")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
            Text(item.summary?.isEmpty == false ? item.summary! : item.ocrText)
                .lineLimit(2)
            if !item.tags.isEmpty {
                Text(item.tags.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
