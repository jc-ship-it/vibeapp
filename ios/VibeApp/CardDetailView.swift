import SwiftUI

struct CardDetailView: View {
    @EnvironmentObject private var store: ScreenshotStore
    @State private var item: ScreenshotItem
    @State private var tagText: String
    @State private var keywordText: String

    init(item: ScreenshotItem) {
        _item = State(initialValue: item)
        _tagText = State(initialValue: item.tags.joined(separator: ", "))
        _keywordText = State(initialValue: item.keywords.joined(separator: ", "))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("卡片详情")
                        .font(.largeTitle.bold())
                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, DesignTokens.Spacing.sm)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("来源")
                        .font(.headline)
                    TextField("来源 App（如小红书、B 站）", text: Binding(
                        get: { item.sourceApp ?? "" },
                        set: { item.sourceApp = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: DesignTokens.Sizes.minTap)
                    TextField("来源场景（帖子/评论等）", text: Binding(
                        get: { item.sourceContext ?? "" },
                        set: { item.sourceContext = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: DesignTokens.Sizes.minTap)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("OCR 原文")
                        .font(.headline)
                    TextEditor(text: $item.ocrText)
                        .frame(minHeight: 160)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("摘要")
                        .font(.headline)
                    TextEditor(text: Binding(
                        get: { item.summary ?? "" },
                        set: { item.summary = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 120)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("标签（逗号分隔）")
                        .font(.headline)
                    TextField("例如：学习, 产品, 购物", text: $tagText)
                        .textInputAutocapitalization(.never)
                        .frame(minHeight: DesignTokens.Sizes.minTap)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("关键词（逗号分隔）")
                        .font(.headline)
                    TextField("例如：增长, 复盘", text: $keywordText)
                        .textInputAutocapitalization(.never)
                        .frame(minHeight: DesignTokens.Sizes.minTap)
                }
                .glassCard()
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            item.tags = normalizeList(from: tagText)
            item.keywords = normalizeList(from: keywordText)
            store.update(item: item)
        }
    }

    private func normalizeList(from text: String) -> [String] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
