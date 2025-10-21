import SwiftUI

struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.12), radius: 10, x: 0, y: 6)
            )
    }
}

extension View {
    func cardBackground() -> some View { modifier(CardBackground()) }
}

enum PlanetStyle {
    static func color(for name: String) -> Color {
        switch name.lowercased() {
        case "sun": return .orange
        case "moon": return .indigo
        case "mars": return .red
        case "mercury": return .green
        case "jupiter": return .yellow
        case "venus": return .pink
        case "saturn": return .purple
        case "rahu": return .teal
        case "ketu": return .cyan
        default: return .gray
        }
    }

    static func icon(for name: String) -> String {
        switch name.lowercased() {
        case "sun": return "sun.max.fill"
        case "moon": return "moon.stars.fill"
        case "mars": return "flame.fill"
        case "mercury": return "bolt.fill"
        case "jupiter": return "sparkles"
        case "venus": return "heart.fill"
        case "saturn": return "globe.americas.fill"
        case "rahu": return "aqi.medium"
        case "ketu": return "tornado"
        default: return "circle.fill"
        }
    }
}

struct PlanetChip: View {
    let name: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: PlanetStyle.icon(for: name))
                .imageScale(.small)
            Text(name)
                .font(.subheadline).bold()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(PlanetStyle.color(for: name).opacity(0.15))
        .foregroundColor(PlanetStyle.color(for: name))
        .clipShape(Capsule())
    }
}

