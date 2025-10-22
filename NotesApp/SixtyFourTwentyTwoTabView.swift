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
                        labeledRow("Drekkana", "\(res.fromLagnaDrekkanaSign) (\(res.fromLagnaDrekkanaLord)) · #\(res.fromLagnaDrekkanaNo) [\(res.fromLagnaDrekkanaStartMin)–\(res.fromLagnaDrekkanaEndMin) min]")
                        labeledRow("Navamsha", "\(res.fromLagnaNavamsaSign) (\(res.fromLagnaNavamsaLord)) · #\(res.fromLagnaNavamsaNo) [\(res.fromLagnaNavamsaStartMin)–\(res.fromLagnaNavamsaEndMin) min]")
                    }
                    section(title: "From Moon (8th)", color: .teal) {
                        labeledRow("Drekkana", "\(res.fromMoonDrekkanaSign) (\(res.fromMoonDrekkanaLord)) · #\(res.fromMoonDrekkanaNo) [\(res.fromMoonDrekkanaStartMin)–\(res.fromMoonDrekkanaEndMin) min]")
                        labeledRow("Navamsha", "\(res.fromMoonNavamsaSign) (\(res.fromMoonNavamsaLord)) · #\(res.fromMoonNavamsaNo) [\(res.fromMoonNavamsaStartMin)–\(res.fromMoonNavamsaEndMin) min]")
                    }
                }
                .padding()
            }
            .navigationTitle("64th & 22nd")
            .background(WaterTheme.gradient(for: colorScheme))
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
        HStack { Text(title); Spacer(); Text(value).font(.caption).foregroundColor(.secondary) }
    }
}

