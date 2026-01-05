import SwiftUI

enum CosmicTheme {
    // Deep, rich space backgrounds
    static let background = Color(red: 0.02, green: 0.02, blue: 0.05) // Near black
    static let backgroundDeep = Color(red: 0.04, green: 0.04, blue: 0.08)
    static let nebula = Color(red: 0.15, green: 0.12, blue: 0.25) // Deep purple-indigo
    
    // Vibrant accents for contrast
    static let accent = Color(red: 1.0, green: 0.82, blue: 0.45) // Luminous Gold
    static let accentSoft = Color(red: 0.2, green: 0.85, blue: 0.95) // Electric Cyan
    
    // Text
    static let text = Color.white
    static let secondaryText = Color(white: 0.75)
    
    // UI Elements
    static var panelFill: Color { Color.white.opacity(0.03) } // More subtle
    static var panelStroke: Color { Color.white.opacity(0.1) }
    static var softGlow: Color { Color.white.opacity(0.05) }

    static func gradient(for scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [background, backgroundDeep, nebula.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func glassGradient(tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                tint.opacity(0.25),
                tint.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
