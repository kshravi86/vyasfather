import SwiftUI

struct SixtyFourTwentyTwoTabView: View {
    let ascendant: (sign: String, deg: Int, min: Int)?
    let planetPositions: [PlanetPosition]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let res = SixtyFourTwentyTwoCalcIOS.compute(ascendant: ascendant, planetPositions: planetPositions)
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    section(title: "From Lagna (8th)", color: .indigo) {
                        labeledRow("22nd Drekkana Lord", res.fromLagnaDrekkanaLord)
                        labeledRow("64th Navamsha Lord", res.fromLagnaNavamsaLord)
                    }
                    section(title: "From Moon (8th)", color: .teal) {
                        labeledRow("22nd Drekkana Lord", res.fromMoonDrekkanaLord)
                        labeledRow("64th Navamsha Lord", res.fromMoonNavamsaLord)
                    }
                }
                .padding()
            }
            .navigationTitle("64th Navamsha & 22nd Drekkana")
            .background(CosmicTheme.gradient(for: colorScheme))
        }
    }

    @ViewBuilder
    private func section<T: View>(title: String, color: Color, @ViewBuilder content: () -> T) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "circle.hexagongrid").foregroundColor(color)
                Text(title).font(.headline)
            }
            content()
        }
        .cardBackground()
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack { Text(title); Spacer(); Text(value).font(.caption).foregroundColor(CosmicTheme.secondaryText) }
    }
}
