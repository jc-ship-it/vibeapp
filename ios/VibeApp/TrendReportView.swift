import SwiftUI

struct TrendReportView: View {
    let report: TrendReport

    var body: some View {
        NavigationView {
            List {
                Section("时间范围") {
                    Text("\(report.periodStart.formatted(date: .abbreviated, time: .omitted)) - \(report.periodEnd.formatted(date: .abbreviated, time: .omitted))")
                }

                Section("总结") {
                    Text(report.summary)
                }

                if !report.highlights.isEmpty {
                    Section("趋势与相似点") {
                        ForEach(report.highlights, id: \.self) { item in
                            Text(item)
                        }
                    }
                }
            }
            .navigationTitle("AI 复盘")
        }
    }
}
