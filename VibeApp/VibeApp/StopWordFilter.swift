import Foundation

/// 过滤标签和关键词中的噪音词汇（UI 元素、网络指示器等）
enum StopWordFilter {
    private static let stopWords: Set<String> = [
        // UI 元素
        "收起", "展开", "返回", "确定", "取消", "设置", "更多",
        "分享", "复制", "删除", "编辑", "完成", "下一步", "上一步",
        "关闭", "打开", "刷新", "加载", "搜索", "管理",
        // 网络/系统
        "4G", "5G", "WiFi", "LTE", "VPN", "GPS",
        // 时间
        "上午", "下午", "今天", "昨天", "刚刚",
    ]

    /// 过滤标签：排除停用词，并满足最小长度
    static func filterTags(_ tags: [String]) -> [String] {
        tags.filter { tag in
            let t = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { return false }
            guard !stopWords.contains(t) else { return false }
            guard !t.allSatisfy(\.isNumber) else { return false }
            // 中文至少 2 字，英文至少 3 字
            let hasChinese = t.contains { c in
                c.unicodeScalars.first.map { $0.value >= 0x4E00 && $0.value <= 0x9FFF } ?? false
            }
            let minLength = hasChinese ? 2 : 3
            return t.count >= minLength
        }
    }

    /// 过滤关键词：复用标签规则
    static func filterKeywords(_ keywords: [String]) -> [String] {
        filterTags(keywords)
    }
}
