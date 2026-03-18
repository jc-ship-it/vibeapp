import SwiftUI

struct TrendReportView: View {
    let report: TrendReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                if !report.similarities.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("标签")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                ForEach(report.similarities.prefix(6), id: \.self) { tag in
                                    Text(shortenTag(tag, maxCount: 5))
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .padding(.horizontal, DesignTokens.Spacing.xs)
                                        .padding(.vertical, DesignTokens.Spacing.xs / 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.secondary.opacity(0.15))
                                        )
                                }
                            }
                        }
                    }
                    .glassCard()
                }

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

    private func shortenTag(_ text: String, maxCount: Int) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count > maxCount else { return t }
        return String(t.prefix(maxCount))
    }
}
