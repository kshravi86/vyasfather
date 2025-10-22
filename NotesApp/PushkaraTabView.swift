import SwiftUI

struct PushkaraTabView: View {
    let planetPositions: [PlanetPosition]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let eval = PushkaraUtils.evaluate(planetPositions: planetPositions)
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(eval.filter { $0.isPushkara }) { e in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            PlanetChip(name: e.planet)
                            Spacer()
                            if let d9 = e.d9Sign {
                                TagBadge(text: d9, color: .teal)
                            }
                        }
                        .cardBackground()
                    }
                    if eval.filter({ $0.isPushkara }).isEmpty {
                        Text("No planets in Pushkara Navamsha")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Pushkara Navamsha")
            .background(WaterTheme.gradient(for: colorScheme))
        }
    }
}

