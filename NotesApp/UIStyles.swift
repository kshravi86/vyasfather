import SwiftUI

struct CardBackground: ViewModifier {
    var tint: Color

    func body(content: Content) -> some View {
        content
            .padding(20)
            .cosmicGlass(cornerRadius: 24, tint: tint, highlightOpacity: 0.15)
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
            )
            .background(
                shape
                    .fill(CosmicTheme.glassGradient(tint: tint))
                    .opacity(highlightOpacity)
            )
            .overlay(
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.05),
                                .white.opacity(0.05),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 8)
    }
}

extension View {
    func cardBackground(tint: Color = CosmicTheme.accent) -> some View {
        modifier(CardBackground(tint: tint))
    }

    func cosmicGlass(
        cornerRadius: CGFloat = 20,
        tint: Color = CosmicTheme.accent,
        highlightOpacity: Double = 0.2
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
        HStack(spacing: isCompact ? 6 : 8) {
            Image(systemName: PlanetStyle.icon(for: name))
                .font(isCompact ? .subheadline : .title3)
                .foregroundColor(PlanetStyle.color(for: name))
                .shadow(color: PlanetStyle.color(for: name).opacity(0.6), radius: 8, x: 0, y: 0)
            if !isCompact {
                Text(name)
                    .font(.body.weight(.medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, isCompact ? 10 : 16)
        .padding(.vertical, isCompact ? 6 : 10)
        .cosmicGlass(cornerRadius: isCompact ? 12 : 16, tint: PlanetStyle.color(for: name), highlightOpacity: 0.15)
    }
}

struct TagBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.xs.bold()) // .xs is not standard, reverting to caption.bold()
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundColor(color) // Text color matches tint for a glowing effect
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(
                        Capsule().stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}
