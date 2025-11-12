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
        planetKind(for: name)?.color ?? .white
    }

    static func icon(for name: String) -> String {
        planetKind(for: name)?.iconName ?? "circle.fill"
    }

    private static func planetKind(for name: String) -> PlanetKind? {
        PlanetKind(label: name)
    }
}

struct PlanetChip: View {
    let name: String
    var isCompact: Bool = false
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: PlanetStyle.icon(for: name))
                .font(isCompact ? .body : .title3)
                .foregroundColor(PlanetStyle.color(for: name))
            if !isCompact {
                Text(name)
                    .font(.headline)
                    .foregroundColor(CosmicTheme.text)
            }
        }
        .padding(.horizontal, isCompact ? 8 : 16)
        .padding(.vertical, isCompact ? 4 : 10)
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
