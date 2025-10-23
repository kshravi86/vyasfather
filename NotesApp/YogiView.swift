import SwiftUI

struct YogiView: View {
    let result: YogiCalculator.YogiResult
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary").font(.headline)
                    HStack(spacing: 8) {
                        PlanetChip(name: result.yogiPlanet)
                        PlanetChip(name: result.sahayogi)
                        PlanetChip(name: result.avayogiPlanet)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .cardBackground()
                sectionCard(title: "Yogi", icon: PlanetStyle.icon(for: result.yogiPlanet), color: PlanetStyle.color(for: result.yogiPlanet)) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            PlanetChip(name: result.yogiPlanet)
                            Spacer()
                            Text(result.formatDegrees(result.yogiPoint))
                                .font(.caption)
                                .foregroundColor(CosmicTheme.secondaryText)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(CosmicTheme.secondaryText)
                                .imageScale(.small)
                            Text("\(result.yogiNakshatra) p\(result.yogiPada) · \(result.yogiSign)")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.secondaryText)
                        }
                    }
                }

                sectionCard(title: "Sahayogi", icon: "person.2.fill", color: .teal) {
                    HStack {
                        PlanetChip(name: result.sahayogi)
                        Spacer()
                        Text("Sign lord of Yogi point")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.secondaryText)
                    }
                }

                sectionCard(title: "Avayogi", icon: PlanetStyle.icon(for: result.avayogiPlanet), color: PlanetStyle.color(for: result.avayogiPlanet)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            PlanetChip(name: result.avayogiPlanet)
                            Spacer()
                            Text(result.formatDegrees(result.avayogiPoint))
                                .font(.caption)
                                .foregroundColor(CosmicTheme.secondaryText)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(CosmicTheme.secondaryText)
                                .imageScale(.small)
                            Text("\(result.avayogiNakshatra) p\(result.avayogiPada) · \(result.avayogiSign)")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.secondaryText)
                        }
                        if let via6th = result.avayogiVia6th {
                            HStack(spacing: 8) {
                                Image(systemName: "arrowshape.turn.up.right.fill")
                                    .imageScale(.small)
                                    .foregroundColor(CosmicTheme.secondaryText)
                                Text("6th from Yogi: \(via6th)")
                                    .font(.caption)
                                    .foregroundColor(CosmicTheme.secondaryText)
                            }
                        }
                    }
                }
                // Share
                if #available(iOS 16.0, *) {
                    let shareText = buildShareText()
                    ShareLink(item: shareText) {
                        Label("Share Summary", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CosmicTheme.accent)
                }
            }
            .padding()
        }
        .navigationTitle("Yogi & Avayogi")
        .background(CosmicTheme.gradient(for: colorScheme))
    }

    private func buildShareText() -> String {
        var lines: [String] = []
        lines.append("Yogi: \(result.yogiPlanet) — \(result.yogiNakshatra) p\(result.yogiPada) · \(result.yogiSign) @ \(result.formatDegrees(result.yogiPoint))")
        lines.append("Sahayogi: \(result.sahayogi) (sign lord of Yogi point)")
        lines.append("Avayogi: \(result.avayogiPlanet) — \(result.avayogiNakshatra) p\(result.avayogiPada) · \(result.avayogiSign) @ \(result.formatDegrees(result.avayogiPoint))")
        if let via6 = result.avayogiVia6th { lines.append("(6th from Yogi: \(via6))") }
        return lines.joined(separator: "\n")
    }

    private func sectionCard<T: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> T) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            content()
        }
        .cardBackground()
    }
}
