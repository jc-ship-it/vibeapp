import SwiftUI

struct TrendsView: View {
    @EnvironmentObject private var store: ScreenshotStore
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @AppStorage("vibeapp_trend_enabled") private var isTrendEnabled: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    trendControlCard

                    if store.reports.isEmpty {
                        ContentUnavailableView(
                            "还没有趋势",
                            systemImage: "waveform.path.ecg",
                            description: Text("在首页导入截图，并开启趋势后生成总结。")
                        )
                    } else {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("趋势报告")
                                .font(.title2.bold())

                            ForEach(store.reports) { report in
                                NavigationLink(destination: TrendReportView(report: report)) {
                                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                        Text(report.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(report.summary)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                        Text("\(report.periodStart.formatted(date: .abbreviated, time: .omitted)) - \(report.periodEnd.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: DesignTokens.Sizes.listRowMinHeight, alignment: .leading)
                                    .glassCard()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.9), value: store.reports.count)
            .navigationTitle("趋势")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var trendControlCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("趋势")
                        .font(.title2.bold())
                    Text(isTrendEnabled
                         ? "已开启。新的截图会参与趋势分析，仅上传识别后的文字。"
                         : "开启后，根据截图生成趋势总结，仅上传识别后的文字。")
                    .font(.callout)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $isTrendEnabled)
                    .labelsHidden()
            }

            if isTrendEnabled {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    Task { await generateReport() }
                } label: {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isAnalyzing ? "正在生成趋势总结..." : "生成趋势总结")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: DesignTokens.Sizes.primaryButtonHeight)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAnalyzing || store.items.isEmpty)

                if let analysisError {
                    Text(analysisError)
                        .font(.callout)
                        .foregroundColor(.red)
                }
            }
        }
        .glassCard()
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: isTrendEnabled)
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: isAnalyzing)
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: analysisError)
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
        } catch {
            analysisError = "生成失败：\(error.localizedDescription)"
        }
    }
}
