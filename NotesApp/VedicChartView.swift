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
        let planetLine: String = inSign.map { p in
            let base = abbrev[p.name] ?? String(p.name.prefix(2))
            return base + (p.retrograde ? "(R)" : "")
        }.joined(separator: " ")
        let isLagna = (ascendantSign == sign)
        VStack(alignment: .leading, spacing: 4) {
            if isLagna { Text("Lagna").font(.caption2).bold() }
            if !planetLine.isEmpty {
                Text(planetLine)
                    .font(.caption)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
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
        .accessibilityLabel("\(sign) \(isLagna ? "Lagna" : "") \(planetLine)")
    }
}

