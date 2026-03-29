import SwiftUI

enum CosmicTheme {
    // Atmospheric deep-space palette
    static let background = Color(red: 0.03, green: 0.05, blue: 0.09)
    static let backgroundDeep = Color(red: 0.02, green: 0.03, blue: 0.06)
    static let nebula = Color(red: 0.09, green: 0.24, blue: 0.33)
    static let midnight = Color(red: 0.04, green: 0.07, blue: 0.12)

    // Accent colors
    static let accent = Color(red: 0.96, green: 0.79, blue: 0.40)
    static let accentSoft = Color(red: 0.36, green: 0.82, blue: 0.89)
    static let rose = Color(red: 0.94, green: 0.53, blue: 0.61)
    static let ember = Color(red: 0.91, green: 0.46, blue: 0.29)
    static let starlight = Color(red: 0.97, green: 0.98, blue: 1.0)

    // Text
    static let text = Color.white
    static let secondaryText = Color(red: 0.73, green: 0.78, blue: 0.85)

    // UI surfaces
    static var panelFill: Color { Color.white.opacity(0.06) }
    static var panelStroke: Color { Color.white.opacity(0.12) }
    static var softGlow: Color { Color.white.opacity(0.08) }

    static func gradient(for scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                backgroundDeep,
                midnight,
                background,
                nebula.opacity(0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var deepSpace: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.01, green: 0.03, blue: 0.07),
                midnight,
                backgroundDeep,
                Color(red: 0.01, green: 0.02, blue: 0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.30),
                rose.opacity(0.16),
                accentSoft.opacity(0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var auroraGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentSoft.opacity(0.28),
                rose.opacity(0.18),
                accent.opacity(0.22)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func glassGradient(tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.10),
                tint.opacity(0.26),
                tint.opacity(0.06),
                Color.black.opacity(0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
