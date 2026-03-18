import SwiftUI
import UIKit

struct TimelineView: View {
    @EnvironmentObject private var store: ScreenshotStore
    @State private var searchText = ""
    @State private var selectedTag = "全部"
    @State private var isManaging = false
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var showDeleteAlert = false
    @State private var deleteAlertMessage = ""
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
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        managePanel

                        VStack(spacing: DesignTokens.Spacing.sm) {
                            ForEach(filteredItems) { item in
                                if isManaging {
                                    Button {
                                        toggleSelection(item.id)
                                    } label: {
                                        SelectableCardRowView(
                                            item: item,
                                            isSelected: selectedItemIDs.contains(item.id)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    NavigationLink(destination: CardDetailView(item: item)) {
                                        CardRowView(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
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
        .alert("删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                store.deleteItems(ids: selectedItemIDs)
                isManaging = false
                selectedItemIDs.removeAll()
            }
        } message: {
            Text(deleteAlertMessage)
        }
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

    private var visibleItemIDs: Set<UUID> {
        Set(filteredItems.map(\.id))
    }

    private var allVisibleSelected: Bool {
        !visibleItemIDs.isEmpty && selectedItemIDs == visibleItemIDs
    }

    private var managePanel: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Button(isManaging ? "完成" : "管理") {
                    if isManaging {
                        isManaging = false
                        selectedItemIDs.removeAll()
                    } else {
                        isManaging = true
                    }
                }
                .buttonStyle(.bordered)

                Spacer()

                if isManaging {
                    Button(allVisibleSelected ? "取消全选" : "全选") {
                        toggleSelectAllVisible()
                    }
                    .buttonStyle(.bordered)

                    Button {
                        requestDeleteSelected()
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "trash")
                            Text("删除")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.red)
                    .disabled(selectedItemIDs.isEmpty)
                }
            }
        }
        .glassCard()
    }

    private func toggleSelection(_ id: UUID) {
        if selectedItemIDs.contains(id) {
            selectedItemIDs.remove(id)
        } else {
            selectedItemIDs.insert(id)
        }
    }

    private func toggleSelectAllVisible() {
        if allVisibleSelected {
            selectedItemIDs.removeAll()
        } else {
            selectedItemIDs = visibleItemIDs
        }
    }

    private func requestDeleteSelected() {
        guard !selectedItemIDs.isEmpty else { return }
        let isAll = allVisibleSelected
        deleteAlertMessage = isAll ? "是否全部都要删除？" : "是否删除选中的 \(selectedItemIDs.count) 条？"
        showDeleteAlert = true
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

private struct SelectableCardRowView: View {
    let item: ScreenshotItem
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            CardRowView(item: item)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.primary)
                    .padding(DesignTokens.Spacing.sm)
                    .font(.system(size: 22, weight: .bold))
            }
        }
    }
}
