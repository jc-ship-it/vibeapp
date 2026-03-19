import SwiftUI
import Charts

struct TrendReportView: View {
    @EnvironmentObject private var store: ScreenshotStore
    let report: TrendReport

    private var itemsInRange: [ScreenshotItem] {
        store.items.filter { $0.createdAt >= report.periodStart && $0.createdAt <= report.periodEnd }
    }

    private var tagCountsInRange: [String: Int] {
        var counts: [String: Int] = [:]
        for item in itemsInRange {
            for tag in StopWordFilter.filterTags(item.tags) {
                counts[tag, default: 0] += 1
            }
        }
        return counts
    }

    private var topTagsFiltered: [String] {
        tagCountsInRange
            .filter { $0.value >= 3 }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map(\.key)
    }

    private var displayTags: [String] {
        let fromReport = StopWordFilter.filterTags(report.similarities)
        let fromData = topTagsFiltered
        let dataSet = Set(fromData)
        let merged = fromReport.filter { dataSet.contains($0) }
        return merged.isEmpty ? fromData : merged
    }

    private struct DayCount: Identifiable {
        let date: Date
        let count: Int
        var id: Date { date }
    }

    private var dailyCounts: [DayCount] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]
        for item in itemsInRange {
            let day = calendar.startOfDay(for: item.createdAt)
            counts[day, default: 0] += 1
        }
        var current = calendar.startOfDay(for: report.periodStart)
        let end = calendar.startOfDay(for: report.periodEnd)
        var result: [DayCount] = []
        while current <= end {
            result.append(DayCount(date: current, count: counts[current] ?? 0))
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                if !dailyCounts.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("每日截图数")
                            .font(.headline)
                        Chart(dailyCounts) { point in
                            BarMark(
                                x: .value("日期", point.date),
                                y: .value("数量", point.count)
                            )
                            .foregroundStyle(DesignTokens.Colors.accent)
                        }
                        .frame(height: 120)
                    }
                    .glassCard()
                }

                if !displayTags.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("标签")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                ForEach(displayTags.prefix(5), id: \.self) { tag in
                                    Button {
                                        store.historyPreselectedTag = tag
                                    } label: {
                                        Text(shortenTag(tag, maxCount: 8))
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .padding(.horizontal, DesignTokens.Spacing.sm)
                                            .padding(.vertical, DesignTokens.Spacing.xs / 2)
                                            .background(
                                                Capsule()
                                                    .fill(Color.secondary.opacity(0.15))
                                            )
                                    }
                                    .buttonStyle(.plain)
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
                            Text(naturalTrendDescription(item))
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

    private func naturalTrendDescription(_ trend: String) -> String {
        if let startRange = trend.range(of: "围绕"),
           let endRange = trend.range(of: "的共性") {
            let topic = String(trend[startRange.upperBound..<endRange.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            if !topic.isEmpty {
                return "最近你关注「\(topic)」的内容明显增多"
            }
        }
        return trend
    }

    private func shortenTag(_ text: String, maxCount: Int) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count > maxCount else { return t }
        return String(t.prefix(maxCount))
    }
}
