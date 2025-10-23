import SwiftUI

struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
    }
}

extension View {
    func cardBackground() -> some View { modifier(CardBackground()) }
}

enum PlanetStyle {
    static func color(for name: String) -> Color {
        switch name.lowercased() {
        case "sun": return .yellow
        case "moon": return .cyan
        case "mars": return .red
        case "mercury": return .mint
        case "jupiter": return .orange
        case "venus": return .pink
        case "saturn": return .indigo
        case "rahu": return .purple
        case "ketu": return .gray
        default: return .white
        }
    }

    static func icon(for name: String) -> String {
        switch name.lowercased() {
        case "sun": return "sun.max.fill"
        case "moon": return "moon.fill"
        case "mars": return "flame.fill"
        case "mercury": return "bolt.fill"
        case "jupiter": return "sparkles"
        case "venus": return "heart.fill"
        case "saturn": return "globe.americas.fill"
        case "rahu": return "arrow.up.circle.fill"
        case "ketu": return "arrow.down.circle.fill"
        default: return "circle.fill"
        }
    }
}

struct PlanetChip: View {
    let name: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: PlanetStyle.icon(for: name))
                .font(.title3)
                .foregroundColor(PlanetStyle.color(for: name))
            Text(name)
                .font(.headline)
                .foregroundColor(CosmicTheme.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

struct TagBadge: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}
