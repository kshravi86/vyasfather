import SwiftUI

struct NavamshaLordsTabView: View {
    let planetPositions: [PlanetPosition]
    let ascendant: (sign: String, deg: Int, min: Int)?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                let d9 = VargaCalculatorIOS.computeD9(planetPositions: planetPositions, ascendant: ascendant)
                VStack(spacing: 12) {
                    sectionHeader("D9 Ascendant: \(d9.ascSign)")
                    ForEach(d9.entries) { e in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            PlanetChip(name: e.planet)
                            Spacer(minLength: 8)
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Navamsha: \(e.sign)  ·  H\(e.house)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                let lord = signLord(of: e.sign)
                                HStack(spacing: 4) {
                                    Text("Lord:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    TagBadge(text: lord, color: PlanetStyle.color(for: lord))
                                }
                            }
                        }
                        .cardBackground()
                    }
                }
                .padding()
            }
            .navigationTitle("Navamsha Lords")
            .background(WaterTheme.gradient(for: colorScheme))
        }
    }

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text).font(.headline)
            Spacer()
        }
    }

    private func signLord(of signName: String) -> String {
        switch (ZodiacSign.from(name: signName) ?? .aries) {
        case .aries: return "Mars"
        case .taurus: return "Venus"
        case .gemini: return "Mercury"
        case .cancer: return "Moon"
        case .leo: return "Sun"
        case .virgo: return "Mercury"
        case .libra: return "Venus"
        case .scorpio: return "Mars"
        case .sagittarius: return "Jupiter"
        case .capricorn: return "Saturn"
        case .aquarius: return "Saturn"
        case .pisces: return "Jupiter"
        }
    }
}

