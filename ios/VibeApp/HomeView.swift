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
            ZStack(alignment: .top) {
                TimelineView(title: "首页")

                if isProcessing {
                    ProgressView("正在识别文字...")
                        .padding(8)
                        .background(.thinMaterial)
                        .cornerRadius(10)
                        .padding(.top, 8)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top, 56)
                }

                if isAnalyzing {
                    ProgressView("正在生成复盘...")
                        .padding(8)
                        .background(.thinMaterial)
                        .cornerRadius(10)
                        .padding(.top, 56)
                }

                if let analysisError {
                    Text(analysisError)
                        .foregroundColor(.red)
                        .padding(.top, 96)
                }
            }
            .toolbar {
                Button {
                    Task { await generateReport() }
                } label: {
                    Label("生成总结", systemImage: "sparkles")
                }

                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 20,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("导入截图", systemImage: "photo.on.rectangle")
                }
            }
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
                highlights: result.similarities + result.trends
            )
            store.setReport(report)
            showReport = true
        } catch {
            analysisError = "生成失败：\(error.localizedDescription)"
        }
    }
}
