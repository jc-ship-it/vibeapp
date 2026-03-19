import SwiftUI

struct CardDetailView: View {
    @EnvironmentObject private var store: ScreenshotStore
    @Environment(\.dismiss) private var dismiss
    @State private var item: ScreenshotItem
    @State private var isRetrying = false
    @State private var showDeleteAlert = false

    init(item: ScreenshotItem) {
        _item = State(initialValue: item)
    }

    private var needsAIRetry: Bool {
        item.summary == nil && !item.ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, DesignTokens.Spacing.sm)

                if needsAIRetry {
                    Button {
                        Task { await retryAISummary() }
                    } label: {
                        HStack {
                            if isRetrying {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(isRetrying ? "正在重试..." : "重试 AI 摘要")
                        }
                        .font(.callout)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(DesignTokens.Radius.sm)
                    }
                    .disabled(isRetrying)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(item.summary ?? "尚未生成摘要")
                        .font(.body)
                        .foregroundColor(item.summary == nil ? .secondary : .primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !item.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text(shorten(tag, maxCount: 6))
                                    .font(.caption)
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
                }

                DisclosureGroup("OCR 原文") {
                    Text(item.ocrText)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !item.keywords.isEmpty {
                    DisclosureGroup("关键词") {
                        Text(item.keywords.prefix(8).map { shorten($0, maxCount: 8) }.joined(separator: " · "))
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Text("删除此卡片")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                }
                .padding(.top, DesignTokens.Spacing.md)
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: shareText,
                    subject: Text("Peeqi 卡片"),
                    message: Text(shareText)
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(item.summary == nil && item.tags.isEmpty)
            }
        }
        .onDisappear {
            store.update(item: item)
        }
        .alert("删除卡片", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                store.deleteItems(ids: [item.id])
                dismiss()
            }
        } message: {
            Text("确定要删除这张卡片吗？")
        }
    }

    private var shareText: String {
        var parts: [String] = []
        if let s = item.summary { parts.append(s) }
        if !item.tags.isEmpty { parts.append(item.tags.joined(separator: " · ")) }
        return parts.joined(separator: "\n")
    }

    private func retryAISummary() async {
        guard !item.ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isRetrying = true
        defer { isRetrying = false }
        do {
            let result = try await AIService.shared.analyzeCard(text: item.ocrText)
            item.summary = result.summary.isEmpty ? nil : result.summary
            item.tags = StopWordFilter.filterTags(result.tags)
            item.keywords = StopWordFilter.filterKeywords(result.keywords)
            store.update(item: item)
        } catch {
            // 静默失败，保持重试横幅可见
        }
    }

    private func shorten(_ text: String, maxCount: Int) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count > maxCount else { return t }
        return String(t.prefix(maxCount))
    }
}
