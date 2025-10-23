import SwiftUI
import CoreLocation

struct YogiTabView: View {
    let planetPositions: [PlanetPosition]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            Group {
                if let sun = planetPositions.first(where: { $0.name == "Sun" }),
                   let moon = planetPositions.first(where: { $0.name == "Moon" }) {
                    let result = YogiCalculator.calculate(sunLongitude: sun.longitude, moonLongitude: moon.longitude)
                    YogiView(result: result)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Waiting for Sun/Moon positions...")
                            .foregroundColor(CosmicTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(CosmicTheme.gradient(for: colorScheme))
                }
            }
            .navigationTitle("Yogi")
        }
    }
}

