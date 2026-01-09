import SwiftUI

struct NavamshaLordsTabView: View {
    let planetPositions: [PlanetPosition]
    let ascendant: (sign: String, deg: Int, min: Int)?
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewMode: String = "Chart"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // View Mode Switcher
                Picker("View Mode", selection: $viewMode) {
                    Text("Chart").tag("Chart")
                    Text("List").tag("List")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                let d9 = VargaCalculatorIOS.computeD9(planetPositions: planetPositions, ascendant: ascendant)

                if viewMode == "Chart" {
                    d9ChartView(d9: d9)
                        .transition(.opacity)
                } else {
                    d9ListView(d9: d9)
                        .transition(.opacity)
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Navamsha (D9)")
        .navigationBarTitleDisplayMode(.inline)
        .background(CosmicTheme.gradient(for: colorScheme))
        .animation(.easeInOut, value: viewMode)
    }

    // MARK: - Chart View
    private func d9ChartView(d9: (ascSign: String, entries: [D9Entry])) -> some View {
        let d9Ascendant = (sign: d9.ascSign, deg: 0, min: 0)
        let d9Positions = makeD9Positions(entries: d9.entries)

        return VStack(spacing: 16) {
            SouthIndianChartView(
                planetPositions: d9Positions,
                ascendant: d9Ascendant,
                title: "Navamsha Chart",
                subtitle: "Strength, Marriage & Dharma"
            )
            
            // Legend / Info
            VStack(alignment: .leading, spacing: 8) {
                Text("About Navamsha")
                    .font(.headline)
                    .foregroundColor(CosmicTheme.starlight)
                
                Text("The D9 chart is the most important divisional chart. It reveals the inner strength of planets, marriage karma, and the fruits of one's dharma.")
                    .font(.body)
                    .foregroundColor(CosmicTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .cardBackground()
            .padding(.horizontal)
        }
    }

    // MARK: - List View
    private func d9ListView(d9: (ascSign: String, entries: [D9Entry])) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header for Ascendant
            HStack {
                Text("D9 Ascendant:")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(d9.ascSign)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(PlanetStyle.color(for: d9.ascSign))
            }
            .padding()
            .cardBackground()

            Divider()
                .padding(.horizontal)

            // Planets List
            ForEach(d9.entries) { e in
                HStack(alignment: .top) {
                    // Planet Icon/Name
                    VStack {
                        PlanetChip(name: e.planet)
                        Spacer()
                    }
                    .frame(width: 80)

                    Divider()

                    // Details
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Sign:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(e.sign)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("House:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(e.house)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Lord:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            let lord = signLord(of: e.sign)
                            Text(lord)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(PlanetStyle.color(for: lord))
                        }
                    }
                    
                    Spacer()
                    
                    // Optional: Dignity indicator (simplistic)
                    dignityBadge(planet: e.planet, sign: e.sign)
                }
                .padding()
                .cardBackground()
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func makeD9Positions(entries: [D9Entry]) -> [PlanetPosition] {
        return entries.map { entry in
            // Inherit retrograde status from the original positions
            let original = planetPositions.first(where: { $0.name == entry.planet })
            
            return PlanetPosition(
                name: entry.planet,
                longitude: 0, // Ignored by Chart
                sign: entry.sign,
                deg: 0,
                min: 0,
                nakshatra: "",
                pada: 0,
                retrograde: original?.retrograde ?? false
            )
        }
    }

    private func signLord(of signName: String) -> String {
        switch (ZodiacSign.from(name: signName) ?? .aries) {
        case .aries, .scorpio: return "Mars"
        case .taurus, .libra: return "Venus"
        case .gemini, .virgo: return "Mercury"
        case .cancer: return "Moon"
        case .leo: return "Sun"
        case .sagittarius, .pisces: return "Jupiter"
        case .capricorn, .aquarius: return "Saturn"
        }
    }
    
    @ViewBuilder
    private func dignityBadge(planet: String, sign: String) -> some View {
        // Very basic dignity check for UI enhancement
        // Real logic is complex, this is just for visual flare if matches
        if let dignity = simpleDignity(planet: planet, sign: sign) {
            Text(dignity)
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(dignityColor(dignity).opacity(0.2))
                .foregroundColor(dignityColor(dignity))
                .cornerRadius(4)
        }
    }
    
    private func simpleDignity(planet: String, sign: String) -> String? {
        // Simplified exaltation/own sign logic
        // TODO: Move to a shared calculator if needed elsewhere
        switch planet {
        case "Sun":
            if sign == "Aries" { return "Exalted" }
            if sign == "Leo" { return "Own" }
            if sign == "Libra" { return "Debilitated" }
        case "Moon":
            if sign == "Taurus" { return "Exalted" }
            if sign == "Cancer" { return "Own" }
            if sign == "Scorpio" { return "Debilitated" }
        case "Mars":
            if sign == "Capricorn" { return "Exalted" }
            if sign == "Aries" || sign == "Scorpio" { return "Own" }
            if sign == "Cancer" { return "Debilitated" }
        case "Mercury":
            if sign == "Virgo" { return "Exalted" } // Also Own
            if sign == "Gemini" { return "Own" }
            if sign == "Pisces" { return "Debilitated" }
        case "Jupiter":
            if sign == "Cancer" { return "Exalted" }
            if sign == "Sagittarius" || sign == "Pisces" { return "Own" }
            if sign == "Capricorn" { return "Debilitated" }
        case "Venus":
            if sign == "Pisces" { return "Exalted" }
            if sign == "Taurus" || sign == "Libra" { return "Own" }
            if sign == "Virgo" { return "Debilitated" }
        case "Saturn":
            if sign == "Libra" { return "Exalted" }
            if sign == "Capricorn" || sign == "Aquarius" { return "Own" }
            if sign == "Aries" { return "Debilitated" }
        default: return nil
        }
        return nil
    }
    
    private func dignityColor(_ dignity: String) -> Color {
        switch dignity {
        case "Exalted": return .green
        case "Own": return .blue
        case "Debilitated": return .red
        default: return .gray
        }
    }
}