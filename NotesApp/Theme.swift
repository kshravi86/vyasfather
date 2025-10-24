import SwiftUI

enum CosmicTheme {
    static let background = Color(red: 0.05, green: 0.0, blue: 0.15)
    static let accent = Color(red: 0.9, green: 0.7, blue: 0.3)
    static let text = Color.white
    static let secondaryText = Color(white: 0.7)

    static func gradient(for scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [background, Color(red: 0.1, green: 0.05, blue: 0.25)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}