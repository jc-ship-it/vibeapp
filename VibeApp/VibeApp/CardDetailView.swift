import SwiftUI

struct CardDetailView: View {
    @EnvironmentObject private var store: ScreenshotStore
    @State private var item: ScreenshotItem
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    init(item: ScreenshotItem) {
        _item = State(initialValue: item)
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
                    Text("OCR 原文")
                        .font(.headline)
                    Text(item.ocrText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("摘要")
                        .font(.headline)
                    Text(item.summary ?? "尚未生成摘要。")
                        .font(.body)
                        .foregroundColor(item.summary == nil ? .secondary : .primary)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("标签")
                        .font(.headline)
                    if item.tags.isEmpty {
                        Text("尚未生成标签。")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    } else {
                        let tags = item.tags.prefix(3).map { shorten($0, maxCount: 6) }
                        Text(tags.joined(separator: " · "))
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
                .glassCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("关键词")
                        .font(.headline)
                    if item.keywords.isEmpty {
                        Text("尚未生成关键词。")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    } else {
                        let keywords = item.keywords.prefix(4).map { shorten($0, maxCount: 6) }
                        Text(keywords.joined(separator: " · "))
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
                .glassCard()

                Button {
                    Task { await generateSummaryAndTags() }
                } label: {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isAnalyzing ? "正在生成摘要与标签..." : "用 AI 生成摘要与标签")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: DesignTokens.Sizes.primaryButtonHeight)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAnalyzing)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            store.update(item: item)
        }
    }

    private func generateSummaryAndTags() async {
        guard !item.ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        do {
            let result = try await AIService.shared.analyzeCard(text: item.ocrText)
            item.summary = result.summary.isEmpty ? nil : result.summary
            item.tags = result.tags
            item.keywords = result.keywords
            store.update(item: item)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func shorten(_ text: String, maxCount: Int) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count > maxCount else { return t }
        return String(t.prefix(maxCount))
    }
}
