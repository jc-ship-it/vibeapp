import SwiftUI
import PhotosUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var store: ScreenshotStore
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isProcessing = false
    @State private var isAnalyzing = false
    @State private var showReport = false
    @State private var errorMessage: String?
    @State private var analysisError: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Vibe")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primary)
                        Text("把截图变成可回顾的洞察。")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, DesignTokens.Spacing.sm)

                    VStack(spacing: DesignTokens.Spacing.sm) {
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

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            Task { await generateReport() }
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("生成趋势总结")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: DesignTokens.Sizes.primaryButtonHeight)
                        }
                        .buttonStyle(.bordered)
                    }

                    statusPanel
                        .glassCard()
                        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: isProcessing)
                        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: isAnalyzing)
                        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: errorMessage)
                        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: analysisError)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("最近卡片")
                            .font(.title2.bold())
                        if store.items.isEmpty {
                            Text("还没有内容。先导入几张截图开始。")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(store.items.prefix(3)) { item in
                                HomeCardRow(item: item)
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedItems) { newItems in
                Task {
                    await handleSelectedItems(newItems)
                }
            }
            .sheet(isPresented: $showReport) {
                if let report = store.latestReport {
                    NavigationView {
                        TrendReportView(report: report)
                    }
                }
            }
        }
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("识别状态")
                .font(.headline)
            if isProcessing {
                Text("正在识别截图文字...")
                    .font(.callout)
                    .foregroundColor(.secondary)
            } else if isAnalyzing {
                Text("正在生成趋势总结...")
                    .font(.callout)
                    .foregroundColor(.secondary)
            } else {
                Text("已就绪，等待导入截图。")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundColor(.red)
            }

            if let analysisError {
                Text(analysisError)
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

        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    let result = try await OCRService.shared.recognizeText(from: image)
                    store.addScreenshot(imageData: data, ocrText: result.text, confidence: result.confidence)
                }
            } catch {
                errorMessage = "识别失败：\(error.localizedDescription)"
            }
        }
    }

    private func generateReport() async {
        guard !store.items.isEmpty else {
            analysisError = "暂无可分析的内容"
            return
        }
        analysisError = nil
        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            let texts = store.items.map { $0.ocrText }
            let result = try await AIService.shared.analyze(texts: texts)
            let report = TrendReport(
                periodStart: store.items.last?.createdAt ?? Date(),
                periodEnd: store.items.first?.createdAt ?? Date(),
                summary: result.summary,
                similarities: result.similarities,
                trends: result.trends
            )
            store.setReport(report)
            showReport = true
        } catch {
            analysisError = "生成失败：\(error.localizedDescription)"
        }
    }
}

private struct HomeCardRow: View {
    let item: ScreenshotItem

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(item.summary?.isEmpty == false ? item.summary! : item.ocrText)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .frame(minHeight: DesignTokens.Sizes.listRowMinHeight)
        .glassCard()
    }
}
