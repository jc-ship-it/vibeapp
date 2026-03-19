import SwiftUI
import UIKit

struct TimelineView: View {
    @EnvironmentObject private var store: ScreenshotStore
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var searchDebounceTask: Task<Void, Never>?
    @State private var selectedTag = ""
    @State private var hasAppliedPreselectedTag = false
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
                tagFilterBar

                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        "暂无历史",
                        systemImage: "tray",
                        description: Text("在首页导入截图后，这里会按时间展示。")
                    )
                } else {
                    managePanel

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        ForEach(sections, id: \.date) { section in
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                Text(sectionTitle(for: section.date))
                                    .font(.title3.bold())
                                    .foregroundColor(.primary)

                                VStack(spacing: DesignTokens.Spacing.sm) {
                                    ForEach(Array(section.items.enumerated()), id: \.element.id) { idx, item in
                                        if isManaging {
                                            Button {
                                                toggleSelection(item.id)
                                            } label: {
                                                TimelineRow(
                                                    item: item,
                                                    isProcessing: store.processingIds.contains(item.id),
                                                    isSelected: selectedItemIDs.contains(item.id),
                                                    searchTerm: debouncedSearchText
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        } else {
                                            NavigationLink(destination: CardDetailView(item: item)) {
                                                TimelineRow(
                                                    item: item,
                                                    isProcessing: store.processingIds.contains(item.id),
                                                    isSelected: false,
                                                    searchTerm: debouncedSearchText
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
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
        .onChange(of: searchText) { _, newValue in
            searchDebounceTask?.cancel()
            searchDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    debouncedSearchText = newValue
                }
            }
        }
        .onAppear {
            debouncedSearchText = searchText
            if let tag = store.historyPreselectedTag, !hasAppliedPreselectedTag {
                selectedTag = tag
                hasAppliedPreselectedTag = true
                store.historyPreselectedTag = nil
            }
        }
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
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .disabled(selectedItemIDs.isEmpty)
                }
            }
        }
        .padding(.bottom, DesignTokens.Spacing.sm)
    }

    private var tagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                TagChip(label: "不限", isSelected: selectedTag.isEmpty) {
                    selectedTag = ""
                }

                ForEach(topTags, id: \.self) { tag in
                    TagChip(label: shortenTag(tag, maxCount: 6), isSelected: selectedTag == tag) {
                        selectedTag = tag
                    }
                }

                if !moreTags.isEmpty {
                    Menu {
                        ForEach(moreTags, id: \.self) { tag in
                            Button { selectedTag = tag } label: {
                                Text(shortenTag(tag, maxCount: 6))
                            }
                        }
                        Button { selectedTag = "" } label: { Text("不限") }
                    } label: {
                        Text("更多")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs / 2)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.12))
                            )
                    }
                }
            }
            .padding(.top, DesignTokens.Spacing.xs)
            .padding(.bottom, DesignTokens.Spacing.xs)
        }
    }

    private func shortenTag(_ text: String, maxCount: Int) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count > maxCount else { return t }
        return String(t.prefix(maxCount))
    }

    private var tagCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for item in store.items {
            for tag in item.tags {
                counts[tag, default: 0] += 1
            }
        }
        return counts
    }

    private var topTags: [String] {
        tagCounts
            .sorted { $0.value > $1.value }
            .map(\.key)
            .prefix(8)
            .map { $0 }
    }

    private var moreTags: [String] {
        let sortedKeys = tagCounts
            .sorted { $0.value > $1.value }
            .map(\.key)
        let topSet = Set(topTags)
        return sortedKeys.filter { !topSet.contains($0) }.prefix(20).map { $0 }
    }

    private var filteredItems: [ScreenshotItem] {
        let query = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var items = store.items.filter { item in
            let matchesTag = selectedTag.isEmpty || item.tags.contains(selectedTag)
            guard !query.isEmpty else { return matchesTag }
            let matchesSearch =
                item.ocrText.localizedCaseInsensitiveContains(query) ||
                item.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) }) ||
                (item.summary?.localizedCaseInsensitiveContains(query) ?? false) ||
                item.keywords.contains(where: { $0.localizedCaseInsensitiveContains(query) })
            return matchesTag && matchesSearch
        }
        if !query.isEmpty {
            items = items.sorted { item1, item2 in
                let score1 = searchMatchScore(item1, query: query)
                let score2 = searchMatchScore(item2, query: query)
                if score1 != score2 { return score1 > score2 }
                return item1.createdAt > item2.createdAt
            }
        } else {
            items = items.sorted { $0.createdAt > $1.createdAt }
        }
        return items
    }

    private func searchMatchScore(_ item: ScreenshotItem, query: String) -> Int {
        let q = query.lowercased()
        if item.tags.contains(where: { $0.lowercased() == q }) { return 3 }
        if item.summary?.lowercased().contains(q) == true { return 2 }
        if item.ocrText.lowercased().contains(q) { return 1 }
        if item.keywords.contains(where: { $0.lowercased().contains(q) }) { return 1 }
        return 0
    }

    private var visibleItemIDs: Set<UUID> {
        Set(filteredItems.map(\.id))
    }

    private var allVisibleSelected: Bool {
        !visibleItemIDs.isEmpty && selectedItemIDs == visibleItemIDs
    }

    private struct DateSection: Identifiable {
        let date: Date
        let items: [ScreenshotItem]
        var id: Date { date }
    }

    private var sections: [DateSection] {
        let grouped = Dictionary(grouping: filteredItems) { startOfDay($0.createdAt) }
        let keys = grouped.keys.sorted(by: >)
        return keys.map { DateSection(date: $0, items: (grouped[$0] ?? []).sorted { $0.createdAt > $1.createdAt }) }
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func sectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)

        if calendar.isDate(target, inSameDayAs: today) {
            return "今天"
        }
        if let days = calendar.dateComponents([.day], from: target, to: today).day {
            if days == 1 { return "昨天" }
            if days == 2 { return "前天" }
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
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
        dismissKeyboard()
        let isAll = allVisibleSelected
        deleteAlertMessage = isAll
            ? "是否全部都要删除？"
            : "是否删除选中的 \(selectedItemIDs.count) 条？"
        showDeleteAlert = true
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct TimelineRow: View {
    let item: ScreenshotItem
    var isProcessing: Bool = false
    let isSelected: Bool
    var searchTerm: String = ""

    var body: some View {
        ZStack(alignment: .topTrailing) {
            CardRowView(item: item, isProcessing: isProcessing, searchTerm: searchTerm)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.primary)
                    .padding(DesignTokens.Spacing.sm)
                    .font(.system(size: 22, weight: .bold))
            }
        }
    }
}

private struct CardRowView: View {
    let item: ScreenshotItem
    var isProcessing: Bool = false
    var searchTerm: String = ""

    private func shortenTag(_ text: String, maxCount: Int) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count > maxCount else { return t }
        return String(t.prefix(maxCount))
    }

    private var displaySummary: String {
        if isProcessing { return "正在生成摘要..." }
        if let s = item.summary, !s.isEmpty { return s }
        let preview = String(item.ocrText.prefix(80))
        return item.ocrText.count > 80 ? preview + "…" : preview
    }

    private func highlightedText(_ text: String) -> Text {
        let query = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, let range = text.range(of: query, options: .caseInsensitive) else {
            return Text(text)
        }
        let before = String(text[..<range.lowerBound])
        let match = String(text[range])
        let after = String(text[range.upperBound...])
        return Text(before) + Text(match).bold().foregroundColor(.primary) + Text(after)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)

            if isProcessing {
                Text(displaySummary)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .redacted(reason: .placeholder)
            } else {
                highlightedText(displaySummary)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            if !item.tags.isEmpty && !isProcessing {
                Text(item.tags.prefix(4).map { shortenTag($0, maxCount: 6) }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.sm)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct TagChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.callout)
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs / 2)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.secondary.opacity(0.18) : Color.secondary.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }
}
