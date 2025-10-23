import SwiftUI

struct PushkaraTabView: View {
    let planetPositions: [PlanetPosition]
    let ascendant: (sign: String, deg: Int, min: Int)?
    @Environment(\.colorScheme) private var colorScheme

    private var evaluatedPushkaras: [PushkaraEntry] {
        var eval = PushkaraUtils.evaluate(planetPositions: planetPositions)
        if let asc = ascendant, let lagnaEntry = PushkaraUtils.evaluateLagna(sign: asc.sign, deg: asc.deg, min: asc.min) {
            eval.append(lagnaEntry)
        }
        return eval
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(evaluatedPushkaras.filter { $0.isPushkara }) { e in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            PlanetChip(name: e.planet)
                            Spacer()
                            if let d9 = e.d9Sign {
                                TagBadge(text: d9, color: .teal)
                            }
                        }
                        .cardBackground()
                    }
                    if evaluatedPushkaras.filter({ $0.isPushkara }).isEmpty {
                        Text("No planets or Lagna in Pushkara Navamsha")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.secondaryText)
                    }
                }
                .padding()
            }
            .navigationTitle("Pushkara Navamsha")
            .background(CosmicTheme.gradient(for: colorScheme))
        }
    }
}
