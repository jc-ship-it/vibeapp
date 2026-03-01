import SwiftUI

struct TrendsView: View {
    @EnvironmentObject private var store: ScreenshotStore

    var body: some View {
        NavigationView {
            Group {
                if let report = store.latestReport {
                    TrendReportView(report: report)
                } else {
                    ContentUnavailableView(
                        "暂无趋势分析",
                        systemImage: "waveform.path.ecg",
                        description: Text("请在首页导入截图并生成总结")
                    )
                }
            }
            .navigationTitle("趋势分析")
        }
    }
}
