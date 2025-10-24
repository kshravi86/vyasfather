import SwiftUI

struct NavamshaLordsTabView: View {
    let planetPositions: [PlanetPosition]
    let ascendant: (sign: String, deg: Int, min: Int)?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            let d9 = VargaCalculatorIOS.computeD9(planetPositions: planetPositions, ascendant: ascendant)
            VStack(alignment: .leading, spacing: 16) {
                Text("D9 Ascendant: ")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                + Text(d9.ascSign)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(PlanetStyle.color(for: d9.ascSign))

                Divider()

                ForEach(d9.entries) { e in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Planet:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            PlanetChip(name: e.planet)
                        }
                        HStack {
                            Text("Navamsha Sign:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TagBadge(text: e.sign, color: .gray)
                        }
                        HStack {
                            Text("Navamsha Lord:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            let lord = signLord(of: e.sign)
                            TagBadge(text: lord, color: PlanetStyle.color(for: lord))
                        }
                    }
                    .padding(.vertical, 8)
                    .cardBackground()
                }
            }
            .padding()
        }
        .navigationTitle("Navamsha Lords")
        .background(CosmicTheme.gradient(for: colorScheme))
    }

}
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
