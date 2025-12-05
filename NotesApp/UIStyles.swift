import SwiftUI

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .cosmicGlass(cornerRadius: 24, tint: CosmicTheme.accent.opacity(0.6))
    }
}

private struct CosmicGlass: ViewModifier {
    var cornerRadius: CGFloat
    var tint: Color
    var highlightOpacity: Double

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .background(
                shape
                    .fill(.ultraThinMaterial)
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .background(
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tint.opacity(0.35),
                                        Color.purple.opacity(0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(highlightOpacity)
                    )
                    .shadow(color: tint.opacity(0.25), radius: 12, x: 0, y: 10)
                    .shadow(color: Color.black.opacity(0.35), radius: 25, x: 0, y: 18)
            )
    }
}

extension View {
    func cardBackground() -> some View { modifier(CardBackground()) }

    func cosmicGlass(
        cornerRadius: CGFloat = 20,
        tint: Color = CosmicTheme.accent,
        highlightOpacity: Double = 0.3
    ) -> some View {
        modifier(CosmicGlass(cornerRadius: cornerRadius, tint: tint, highlightOpacity: highlightOpacity))
    }
}

enum PlanetStyle {
    static func color(for name: String) -> Color {
        guard let key = canonicalKey(for: name),
              let style = palette[key] else { return .white }
        return style.color
    }

    static func icon(for name: String) -> String {
        guard let key = canonicalKey(for: name),
              let style = palette[key] else { return "circle.fill" }
        return style.icon
    }

    // Normalizes labels (e.g., "Surya" -> "sun") so styling stays consistent.
    private static func canonicalKey(for name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return aliases[trimmed]
    }

    private static let palette: [String: (color: Color, icon: String)] = [
        "sun": (.yellow, "sun.max.fill"),
        "moon": (.cyan, "moon.fill"),
        "mars": (.red, "flame.fill"),
        "mercury": (.mint, "bolt.fill"),
        "jupiter": (.orange, "sparkles"),
        "venus": (.pink, "heart.fill"),
        "saturn": (.indigo, "globe.americas.fill"),
        "rahu": (.purple, "arrow.up.circle.fill"),
        "ketu": (.gray, "arrow.down.circle.fill")
    ]

    private static let aliases: [String: String] = [
        "sun": "sun", "surya": "sun",
        "moon": "moon", "chandra": "moon",
        "mars": "mars", "mangala": "mars", "kuja": "mars",
        "mercury": "mercury", "budha": "mercury",
        "jupiter": "jupiter", "guru": "jupiter", "brihaspati": "jupiter",
        "venus": "venus", "shukra": "venus",
        "saturn": "saturn", "shani": "saturn",
        "rahu": "rahu",
        "ketu": "ketu"
    ]
}

struct PlanetChip: View {
    let name: String
    var isCompact: Bool = false

    var body: some View {
        HStack(spacing: isCompact ? 6 : 10) {
            Image(systemName: PlanetStyle.icon(for: name))
                .font(isCompact ? .headline : .title3)
                .foregroundColor(PlanetStyle.color(for: name))
                .shadow(color: PlanetStyle.color(for: name).opacity(0.4), radius: 6, x: 0, y: 3)
            if !isCompact {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, isCompact ? 10 : 18)
        .padding(.vertical, isCompact ? 6 : 12)
        .cosmicGlass(cornerRadius: isCompact ? 14 : 20, tint: PlanetStyle.color(for: name), highlightOpacity: 0.45)
    }
}

struct TagBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundColor(.white)
            .cosmicGlass(cornerRadius: 22, tint: color, highlightOpacity: 0.35)
    }
}
