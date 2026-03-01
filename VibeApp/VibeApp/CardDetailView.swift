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
        Form {
            Section("来源") {
                TextField("来源 App（如小红书、B 站）", text: Binding(
                    get: { item.sourceApp ?? "" },
                    set: { item.sourceApp = $0.isEmpty ? nil : $0 }
                ))
                TextField("来源场景（帖子/评论等）", text: Binding(
                    get: { item.sourceContext ?? "" },
                    set: { item.sourceContext = $0.isEmpty ? nil : $0 }
                ))
            }

            Section("OCR 原文") {
                TextEditor(text: $item.ocrText)
                    .frame(minHeight: 160)
            }

            Section("摘要") {
                TextEditor(text: Binding(
                    get: { item.summary ?? "" },
                    set: { item.summary = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 120)
            }

            Section("标签（逗号分隔）") {
                TextField("例如：学习, 产品, 购物", text: $tagText)
                    .textInputAutocapitalization(.never)
            }

            Section("关键词（逗号分隔）") {
                TextField("例如：增长, 复盘", text: $keywordText)
                    .textInputAutocapitalization(.never)
            }
        }
        .navigationTitle("卡片详情")
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
