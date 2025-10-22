import SwiftUI

struct YogasTabView: View {
    let planetPositions: [PlanetPosition]
    let houses: [(index: Int, sign: String, deg: Int, min: Int)]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let results = YogaDetectorIOS.detect(planetPositions: planetPositions, houses: houses)
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    if results.isEmpty {
                        Text("No yogas detected")
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .padding(.top, 12)
                    } else {
                        ForEach(results) { y in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Image(systemName: "star.circle")
                                        .foregroundColor(.orange)
                                    Text(y.name)
                                        .font(.headline)
                                }
                                Text(y.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .cardBackground()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Yogas")
            .background(WaterTheme.gradient(for: colorScheme))
        }
    }
}

