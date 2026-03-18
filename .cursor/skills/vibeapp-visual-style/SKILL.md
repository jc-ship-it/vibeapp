---
name: vibeapp-visual-style
description: VibeApp 项目的视觉设计规范与 SwiftUI 实现约定。用于新建界面、修改样式、保持设计一致性时参考。涉及 DesignTokens、glassCard、间距、圆角、字体层级、动效等。
---

# VibeApp 视觉风格

## Design Tokens 使用规范

所有布局与样式必须引用 `DesignTokens`，禁止硬编码数值。

### 间距 (Spacing)

| Token | 值 | 用途 |
|-------|-----|------|
| `xs` | 8 | 紧凑元素间距、标签与标题 |
| `sm` | 16 | 卡片内部、列表项、常用 padding |
| `md` | 24 | 区块间距、section 之间 |
| `lg` | 32 | 大区块 |
| `xl` | 48 | 底部留白、大留白 |

### 圆角 (Radius)

| Token | 值 | 用途 |
|-------|-----|------|
| `sm` | 12 | 小组件 |
| `md` | 16 | 默认卡片（glassCard 默认） |
| `lg` | 20 | 大卡片 |

### 阴影 (Shadow)

- `light`: `black.opacity(0.06)`，radius 12, y 6
- `soft`: `black.opacity(0.12)`，radius 4, y 2

### 尺寸 (Sizes)

| Token | 值 | 用途 |
|-------|-----|------|
| `minTap` | 44 | 最小点击区域、输入框高度 |
| `primaryButtonHeight` | 52 | 主按钮高度 |
| `listRowMinHeight` | 56 | 列表行最小高度 |

## 卡片样式：glassCard

卡片统一使用 `.glassCard()` 修饰符：

```swift
.content
    .glassCard()  // 默认 cornerRadius: DesignTokens.Radius.md
```

效果：`ultraThinMaterial` 背景 + 圆角 + 双层阴影。

卡片内部结构：
- 外层 `VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm)` 或 `.xs`
- 标题用 `.font(.headline)`
- 副标题/说明用 `.font(.callout)` 或 `.subheadline` + `.foregroundColor(.secondary)`

## 页面布局模式

### 标准页面结构

```swift
ScrollView {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
        // 1. 页面标题区
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("页面标题")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
            Text("副标题或说明")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(.top, DesignTokens.Spacing.sm)

        // 2. 内容区块（多个 glassCard）
        // ...
    }
    .padding(.horizontal, DesignTokens.Spacing.sm)
    .padding(.bottom, DesignTokens.Spacing.xl)
}
.navigationBarTitleDisplayMode(.inline)
```

### 列表行结构

```swift
VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
    Text(日期)
        .font(.caption)
        .foregroundColor(.secondary)
    Text(主内容)
        .font(.headline)
        .foregroundColor(.primary)
        .lineLimit(2)
    if 有标签 {
        Text(标签.join(" · "))
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
}
.frame(minHeight: DesignTokens.Sizes.listRowMinHeight, alignment: .leading)
.glassCard()
```

## 字体层级

| 用途 | 字体 |
|------|------|
| 页面主标题 | `.largeTitle.bold()` |
| 区块标题 | `.title2.bold()` |
| 卡片/列表标题 | `.headline` |
| 正文 | `.body` |
| 次要信息、说明 | `.callout` 或 `.subheadline` + `.secondary` |
| 时间、元信息 | `.caption` + `.secondary` |
| 辅助说明 | `.footnote` + `.secondary` |

## 动效

使用弹簧动画保持一致性：

```swift
.animation(.spring(response: 0.3, dampingFraction: 0.9), value: 依赖状态)
```

交互反馈：主操作可使用 `UIImpactFeedbackGenerator(style: .light).impactOccurred()`。

## 空状态

使用系统 `ContentUnavailableView`：
- 图标选用与场景相关 SF Symbol（如 `tray`、`waveform.path.ecg`）
- 标题简明
- 描述引导下一步操作

## 按钮

- 主操作：`.buttonStyle(.borderedProminent)`
- 次要操作：`.buttonStyle(.bordered)`
- 主按钮结构：`HStack { Icon + Text } .font(.headline) .frame(maxWidth: .infinity, minHeight: DesignTokens.Sizes.primaryButtonHeight)`
- 危险操作（如退出）：`.foregroundColor(.red)` 文本按钮

## 注意事项

- 保持「毛玻璃 + 轻柔阴影」的现代 iOS 风格
- 不使用自定义品牌色，遵循系统语义色（`.primary`、`.secondary`、`.red`）
- 支持系统深色模式（使用语义色即可）
