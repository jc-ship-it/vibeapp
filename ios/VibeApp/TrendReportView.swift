import SwiftUI

struct TrendReportView: View {
    let report: TrendReport

    var body: some View {
        List {
            Section("时间范围") {
                Text("\(report.periodStart.formatted(date: .abbreviated, time: .omitted)) - \(report.periodEnd.formatted(date: .abbreviated, time: .omitted))")
            }

            Section("总结") {
                Text(report.summary)
            }

            if !report.similarities.isEmpty {
                Section("相似点") {
                    ForEach(report.similarities, id: \.self) { item in
                        Text(item)
                    }
                }
            }

            if !report.trends.isEmpty {
                Section("趋势") {
                    ForEach(report.trends, id: \.self) { item in
                        Text(item)
                    }
                }
            }
        }
        .navigationTitle("AI 复盘")
    }
}
