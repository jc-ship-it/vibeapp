import SwiftUI

struct TrendsView: View {
    @EnvironmentObject private var store: ScreenshotStore

    var body: some View {
        NavigationView {
            if store.reports.isEmpty {
                ContentUnavailableView(
                    "暂无趋势分析",
                    systemImage: "waveform.path.ecg",
                    description: Text("请在首页导入截图并生成总结")
                )
                .navigationTitle("趋势分析")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
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
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.bottom, DesignTokens.Spacing.xl)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.9), value: store.reports.count)
                .navigationTitle("趋势分析")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
