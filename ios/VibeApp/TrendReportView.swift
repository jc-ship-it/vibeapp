import SwiftUI

struct TrendReportView: View {
    let report: TrendReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("时间范围")
                        .font(.headline)
                    Text("\(report.periodStart.formatted(date: .abbreviated, time: .omitted)) - \(report.periodEnd.formatted(date: .abbreviated, time: .omitted))")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("总结")
                        .font(.headline)
                    Text(report.summary)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .glassCard()

                if !report.similarities.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("相似点")
                            .font(.headline)
                        ForEach(report.similarities, id: \.self) { item in
                            Text(item)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                    .glassCard()
                }

                if !report.trends.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("趋势")
                            .font(.headline)
                        ForEach(report.trends, id: \.self) { item in
                            Text(item)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                    .glassCard()
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .navigationTitle("趋势报告")
        .navigationBarTitleDisplayMode(.inline)
    }
}
