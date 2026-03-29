import SwiftUI

enum CosmicTheme {
    // Cleaner, brighter cosmic palette
    static let background = Color(red: 0.08, green: 0.12, blue: 0.22)
    static let backgroundDeep = Color(red: 0.12, green: 0.19, blue: 0.34)
    static let nebula = Color(red: 0.33, green: 0.66, blue: 0.90)
    static let midnight = Color(red: 0.20, green: 0.17, blue: 0.38)

    // Accent colors
    static let accent = Color(red: 1.00, green: 0.73, blue: 0.36)
    static let accentSoft = Color(red: 0.34, green: 0.90, blue: 0.78)
    static let rose = Color(red: 0.98, green: 0.58, blue: 0.74)
    static let ember = Color(red: 1.00, green: 0.47, blue: 0.44)
    static let violet = Color(red: 0.67, green: 0.56, blue: 1.00)
    static let starlight = Color(red: 0.97, green: 0.98, blue: 1.0)

    // Text
    static let text = Color.white
    static let secondaryText = Color(red: 0.83, green: 0.88, blue: 0.94)

    // UI surfaces
    static var panelFill: Color { Color.white.opacity(0.10) }
    static var panelStroke: Color { Color.white.opacity(0.18) }
    static var softGlow: Color { Color.white.opacity(0.12) }

    static func gradient(for _: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                midnight,
                backgroundDeep,
                background,
                nebula.opacity(0.45),
                rose.opacity(0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var deepSpace: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.23, blue: 0.49),
                midnight,
                backgroundDeep,
                Color(red: 0.07, green: 0.11, blue: 0.24)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.34),
                rose.opacity(0.24),
                accentSoft.opacity(0.22),
                violet.opacity(0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var auroraGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentSoft.opacity(0.34),
                nebula.opacity(0.28),
                rose.opacity(0.24),
                accent.opacity(0.24)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func glassGradient(tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.18),
                tint.opacity(0.24),
                Color.white.opacity(0.08),
                tint.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
