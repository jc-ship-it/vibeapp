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
                List {
                    ForEach(store.reports) { report in
                        NavigationLink(destination: TrendReportView(report: report)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(report.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(report.summary)
                                    .lineLimit(2)
                                Text("\(report.periodStart.formatted(date: .abbreviated, time: .omitted)) - \(report.periodEnd.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .navigationTitle("趋势分析")
            }
        }
    }
}
