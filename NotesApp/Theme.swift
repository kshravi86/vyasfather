import SwiftUI

enum WaterTheme {
    static let tint: Color = .blue

    static func gradient(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .light:
            return LinearGradient(
                colors: [Color.cyan.opacity(0.25), Color.blue.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color.blue.opacity(0.35), Color.indigo.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
