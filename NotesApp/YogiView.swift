import SwiftUI

struct YogiView: View {
    let result: YogiCalculator.YogiResult
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                YogiCard(result: result)
                SahayogiCard(result: result)
                AvayogiCard(result: result)
            }
            .padding()
        }
        .navigationTitle("Yogi & Avayogi")
        .background(CosmicTheme.gradient(for: colorScheme))
    }
}

private struct YogiCard: View {
    let result: YogiCalculator.YogiResult
    let color = PlanetStyle.color(for: result.yogiPlanet)
    let icon = PlanetStyle.icon(for: result.yogiPlanet)

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(color)
                Text("Yogi")
                    .font(.title2.bold())
                    .foregroundColor(CosmicTheme.text)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    PlanetChip(name: result.yogiPlanet)
                    Spacer()
                    Text(result.formatDegrees(result.yogiPoint))
                        .font(.title3.monospaced())
                        .foregroundColor(CosmicTheme.secondaryText)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(CosmicTheme.secondaryText)
                        .imageScale(.small)
                    Text("\(result.yogiNakshatra) p\(result.yogiPada) · \(result.yogiSign)")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.secondaryText)
                }
            }
        }
        .cardBackground()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.5), lineWidth: 2)
        )
    }
}

private struct SahayogiCard: View {
    let result: YogiCalculator.YogiResult

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.title)
                    .foregroundColor(.teal)
                Text("Sahayogi")
                    .font(.title2.bold())
                    .foregroundColor(CosmicTheme.text)
                Spacer()
            }
            
            HStack {
                PlanetChip(name: result.sahayogi)
                Spacer()
                TagBadge(text: "Sign Lord of Yogi Point", color: .teal)
            }
        }
        .cardBackground()
    }
}

private struct AvayogiCard: View {
    let result: YogiCalculator.YogiResult
    let color = PlanetStyle.color(for: result.avayogiPlanet)
    let icon = PlanetStyle.icon(for: result.avayogiPlanet)

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                Text("Avayogi")
                    .font(.title2.bold())
                    .foregroundColor(CosmicTheme.text)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    PlanetChip(name: result.avayogiPlanet)
                    Spacer()
                    Text(result.formatDegrees(result.avayogiPoint))
                        .font(.title3.monospaced())
                        .foregroundColor(CosmicTheme.secondaryText)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(CosmicTheme.secondaryText)
                        .imageScale(.small)
                    Text("\(result.avayogiNakshatra) p\(result.avayogiPada) · \(result.avayogiSign)")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.secondaryText)
                }
                
                if let via6th = result.avayogiVia6th {
                    HStack(spacing: 8) {
                        Image(systemName: "arrowshape.turn.up.right.fill")
                            .imageScale(.small)
                            .foregroundColor(.red)
                        Text("6th from Yogi: \(via6th)")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                    }
                    .padding(.top, 5)
                }
            }
        }
        .cardBackground()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}