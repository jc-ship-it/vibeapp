import SwiftUI
import PhotosUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var store: ScreenshotStore
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private var todayItems: [ScreenshotItem] {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) ?? Date()
        return store.items.filter { $0.createdAt >= cutoff }
    }

    private var weekCount: Int {
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return store.items.filter { $0.createdAt >= startOfWeek }.count
    }

    private var hasCards: Bool { !store.items.isEmpty }
    private var hasTodayCards: Bool { !todayItems.isEmpty }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    if hasCards {
                        activeStateContent
                    } else {
                        zeroStateContent
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
            .navigationTitle("Peeqi")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 20,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("导入截图", systemImage: "photo.on.rectangle")
                    }
                }
            }
            .onChange(of: selectedItems) { newItems in
                Task {
                    await handleSelectedItems(newItems)
                }
            }
        }
    }

    @ViewBuilder
    private var zeroStateContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("把截图变成可回顾的洞察。")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.top, DesignTokens.Spacing.sm)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("导入截图")
                        .font(.title2.bold())
                    Text("从相册导入截图，在本机识别文字，自动生成摘要与标签。")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 20,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("导入截图")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: DesignTokens.Sizes.primaryButtonHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignTokens.Colors.accent)

                if isProcessing {
                    Text("正在识别截图文字...")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundColor(.red)
                }
            }
            .glassCard()
        }
    }

    @ViewBuilder
    private var activeStateContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("本周 \(weekCount) 张截图")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, DesignTokens.Spacing.xs)

            if hasTodayCards {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("今天")
                        .font(.title3.bold())
                        .foregroundColor(.primary)

                    ForEach(todayItems) { item in
                        NavigationLink(destination: CardDetailView(item: item)) {
                            HomeCardRow(
                                item: item,
                                isProcessing: store.processingIds.contains(item.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("今天还没有新截图", systemImage: "photo.on.rectangle.angled")
                } description: {
                    Text("从相册导入截图开始。")
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundColor(.red)
            }
        }
    }

    private func handleSelectedItems(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        errorMessage = nil
        isProcessing = true
        defer { isProcessing = false }

        for pickerItem in items {
            do {
                guard let data = try await pickerItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { continue }
                let ocrResult = try await OCRService.shared.recognizeText(from: image)
                let screenshotItem = store.addScreenshot(imageData: data, ocrText: ocrResult.text, confidence: ocrResult.confidence)
                store.addToProcessing(screenshotItem.id)

                Task { @MainActor in
                    await runAIAnalysis(for: screenshotItem)
                }
            } catch {
                errorMessage = "识别失败：\(error.localizedDescription)"
            }
        }
        selectedItems = []
    }

    private func runAIAnalysis(for item: ScreenshotItem) async {
        defer { store.removeFromProcessing(item.id) }
        guard !item.ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        do {
            let result = try await AIService.shared.analyzeCard(text: item.ocrText)
            var updated = item
            updated.summary = result.summary.isEmpty ? nil : result.summary
            updated.tags = StopWordFilter.filterTags(result.tags)
            updated.keywords = StopWordFilter.filterKeywords(result.keywords)
            store.update(item: updated)
        } catch {
            // AI 失败：不更新，详情页显示重试横幅
        }
    }
}

private struct HomeCardRow: View {
    let item: ScreenshotItem
    var isProcessing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)

            if isProcessing {
                Text("正在生成摘要...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .redacted(reason: .placeholder)
            } else {
                Text(item.summary?.isEmpty == false ? item.summary! : String(item.ocrText.prefix(80)) + (item.ocrText.count > 80 ? "…" : ""))
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            if !item.tags.isEmpty && !isProcessing {
                Text(item.tags.prefix(4).map { $0 }.joined(separator: " · "))
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
