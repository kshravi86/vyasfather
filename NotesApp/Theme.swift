import SwiftUI

enum CosmicTheme {
    static let background = Color(red: 0.03, green: 0.05, blue: 0.12)
    static let backgroundDeep = Color(red: 0.06, green: 0.1, blue: 0.2)
    static let nebula = Color(red: 0.12, green: 0.16, blue: 0.3)
    static let accent = Color(red: 0.94, green: 0.74, blue: 0.36)
    static let accentSoft = Color(red: 0.32, green: 0.78, blue: 0.86)
    static let text = Color.white
    static let secondaryText = Color(white: 0.74)
    static var panelFill: Color { Color.white.opacity(0.05) }
    static var panelStroke: Color { Color.white.opacity(0.14) }
    static var softGlow: Color { Color.white.opacity(0.08) }

    static func gradient(for scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [background, backgroundDeep, nebula],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func glassGradient(tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                tint.opacity(0.42),
                Color(red: 0.08, green: 0.12, blue: 0.22),
                tint.opacity(0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
