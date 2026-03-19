import SwiftUI

enum DesignTokens {
    enum Colors {
        /// 主色调：浅色模式黑、深色模式白
        static var accent: Color {
            Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? .white : .black
            })
        }
        static var accentOpposite: Color {
            Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? .black : .white
            })
        }
    }

    enum Spacing {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 16
        static let md: CGFloat = 24
        static let lg: CGFloat = 32
        static let xl: CGFloat = 48
    }

    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
    }

    enum Shadow {
        static let light = Color.black.opacity(0.06)
        static let soft = Color.black.opacity(0.12)
    }

    enum Sizes {
        static let minTap: CGFloat = 44
        static let primaryButtonHeight: CGFloat = 52
        static let listRowMinHeight: CGFloat = 56
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = DesignTokens.Radius.md) -> some View {
        self
            .padding(DesignTokens.Spacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: DesignTokens.Shadow.light, radius: 12, x: 0, y: 6)
            .shadow(color: DesignTokens.Shadow.soft, radius: 4, x: 0, y: 2)
    }
}
