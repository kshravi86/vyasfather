import SwiftUI

enum CosmicTheme {
    static let background = Color(red: 0.06, green: 0.09, blue: 0.18)
    static let backgroundDeep = Color(red: 0.09, green: 0.14, blue: 0.28)
    static let nebula = Color(red: 0.25, green: 0.60, blue: 0.94)
    static let midnight = Color(red: 0.16, green: 0.13, blue: 0.36)

    // Accent colors
    static let accent = Color(red: 1.00, green: 0.73, blue: 0.36)
    static let accentSoft = Color(red: 0.26, green: 0.94, blue: 0.82)
    static let rose = Color(red: 0.98, green: 0.58, blue: 0.74)
    static let ember = Color(red: 1.00, green: 0.47, blue: 0.44)
    static let violet = Color(red: 0.58, green: 0.46, blue: 1.00)
    static let starlight = Color(red: 0.97, green: 0.98, blue: 1.0)

    // Text
    static let text = Color.white
    static let secondaryText = Color(red: 0.83, green: 0.88, blue: 0.94)

    // UI surfaces
    static var panelFill: Color { Color.white.opacity(0.12) }
    static var panelStroke: Color { Color.white.opacity(0.22) }
    static var softGlow: Color { Color.white.opacity(0.14) }

    static func gradient(for _: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.07, blue: 0.28),
                midnight,
                backgroundDeep,
                background,
                nebula.opacity(0.50),
                rose.opacity(0.26)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var deepSpace: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.14, green: 0.20, blue: 0.48),
                midnight,
                backgroundDeep,
                Color(red: 0.05, green: 0.08, blue: 0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.44),
                rose.opacity(0.32),
                accentSoft.opacity(0.28),
                violet.opacity(0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var auroraGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentSoft.opacity(0.50),
                nebula.opacity(0.40),
                violet.opacity(0.32),
                rose.opacity(0.28)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func glassGradient(tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.22),
                tint.opacity(0.28),
                Color.white.opacity(0.10),
                tint.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
