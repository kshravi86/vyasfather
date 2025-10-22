import SwiftUI

struct VedicChartView: View {
    let ascendantSign: String?
    let planets: [PlanetPosition]

    // South Indian fixed-sign layout: Pisces at top-left, then clockwise
    private let chartOrder: [String] = [
        "Pisces","Aries","Taurus","Gemini",
        "Cancer","Leo","Virgo","Libra",
        "Scorpio","Sagittarius","Capricorn","Aquarius"
    ]

    private let abbrev: [String:String] = [
        "Sun":"Su","Moon":"Mo","Mercury":"Me","Venus":"Ve","Mars":"Ma",
        "Jupiter":"Ju","Saturn":"Sa","Rahu":"Ra","Ketu":"Ke"
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            ForEach(chartOrder, id: \.self) { sign in
                cell(for: sign)
            }
        }
    }

    @ViewBuilder
    private func cell(for sign: String) -> some View {
        let inSign = planets.filter { $0.sign == sign }
        let groups = chunkPlanets(inSign, maxPerLine: 3)
        let isLagna = (ascendantSign == sign)
        VStack(alignment: .leading, spacing: 4) {
            if isLagna { Text("Lagna").font(.caption2).bold() }
            if !inSign.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(groups.indices, id: \.self) { gi in
                        let linePlanets = groups[gi]
                        HStack(spacing: 6) {
                            ForEach(linePlanets, id: \.id) { p in
                                let label = (abbrev[p.name] ?? String(p.name.prefix(2))) + (p.retrograde ? "(R)" : "")
                                Text(label)
                                    .font(inSign.count >= 4 ? .caption2 : .caption)
                                    .foregroundColor(PlanetStyle.color(for: p.name))
                                    .minimumScaleFactor(0.6)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(minHeight: 44)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .accessibilityLabel("\(sign) \(isLagna ? \"Lagna\" : \"\") \(inSign.map { $0.name }.joined(separator: \" \"))")
    }
    
    private func chunkPlanets(_ planets: [PlanetPosition], maxPerLine: Int) -> [[PlanetPosition]] {
        guard !planets.isEmpty else { return [] }
        var result: [[PlanetPosition]] = []
        var i = 0
        while i < planets.count {
            let end = min(i + maxPerLine, planets.count)
            result.append(Array(planets[i..<end]))
            i = end
        }
        return result
    }
}

