import SwiftUI

private struct PlanetMarker: Identifiable {
    let id = UUID()
    let label: String
    let tint: Color
    let isRetrograde: Bool

    var displayLabel: String {
        isRetrograde ? "\(label)R" : label
    }
}

struct SouthIndianChartView: View {
    let planetPositions: [PlanetPosition]
    let ascendant: (sign: String, deg: Int, min: Int)?

    private let grid: [[String?]] = [
        ["Aries", "Taurus", "Gemini", "Cancer"],
        ["Pisces", nil, nil, "Leo"],
        ["Aquarius", nil, nil, "Virgo"],
        ["Capricorn", "Sagittarius", "Scorpio", "Libra"]
    ]

    private let signAbbrev: [String: String] = [
        "Aries": "Ar", "Taurus": "Ta", "Gemini": "Ge", "Cancer": "Cn",
        "Leo": "Le", "Virgo": "Vi", "Libra": "Li", "Scorpio": "Sc",
        "Sagittarius": "Sg", "Capricorn": "Cp", "Aquarius": "Aq", "Pisces": "Pi"
    ]

    private let planetOrder = ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn", "Rahu", "Ketu"]
    private let planetLabels: [String: String] = [
        "Sun": "Su", "Moon": "Mo", "Mars": "Ma", "Mercury": "Me",
        "Jupiter": "Ju", "Venus": "Ve", "Saturn": "Sa", "Rahu": "Ra", "Ketu": "Ke"
    ]

    private var markersBySign: [String: [PlanetMarker]] {
        var map: [String: [PlanetMarker]] = [:]
        if let asc = ascendant {
            map[asc.sign, default: []].append(
                PlanetMarker(label: "La", tint: CosmicTheme.accent, isRetrograde: false)
            )
        }

        let byName = Dictionary(uniqueKeysWithValues: planetPositions.map { ($0.name, $0) })
        for name in planetOrder {
            guard let pos = byName[name] else { continue }
            let label = planetLabels[name] ?? String(name.prefix(2))
            let tint = PlanetStyle.color(for: name)
            let isRetro = pos.retrograde
            map[pos.sign, default: []].append(
                PlanetMarker(label: label, tint: tint, isRetrograde: isRetro)
            )
        }
        return map
    }

    var body: some View {
        ZStack {
            CosmicBackgroundView()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerView

                    if planetPositions.isEmpty && ascendant == nil {
                        Text("Enter birth details to plot the D1 chart.")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.secondaryText)
                    }

                    chartGrid
                        .frame(maxWidth: 480)
                        .aspectRatio(1, contentMode: .fit)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 80)
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 6) {
            Text("South Indian Chart")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(CosmicTheme.starlight)

            Text("D1 Rasi placement")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.secondaryText)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, CosmicTheme.accent.opacity(0.5), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.top, 6)
        }
    }

    private var chartGrid: some View {
        let gridSize = 4
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: gridSize)
        return LazyVGrid(columns: columns, spacing: 0) {
            ForEach(0..<(gridSize * gridSize), id: \.self) { index in
                let row = index / gridSize
                let col = index % gridSize
                let sign = grid[row][col]
                ChartCell(
                    sign: sign,
                    signLabel: sign.map { signAbbrev[$0] ?? $0 } ?? "",
                    markers: sign.map { markersBySign[$0] ?? [] } ?? []
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
            }
        }
        .background(CosmicTheme.midnight.opacity(0.55))
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

private struct ChartCell: View {
    let sign: String?
    let signLabel: String
    let markers: [PlanetMarker]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)

            if sign != nil {
                VStack(alignment: .leading, spacing: 6) {
                    Text(signLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(CosmicTheme.secondaryText)

                    if markers.isEmpty {
                        Text("--")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.secondaryText.opacity(0.7))
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 4),
                                GridItem(.flexible(), spacing: 4)
                            ],
                            spacing: 4
                        ) {
                            ForEach(markers) { marker in
                                PlanetBadge(marker: marker)
                            }
                        }
                    }
                }
                .padding(6)
            }
        }
        .background(Color.black.opacity(0.2))
    }
}

private struct PlanetBadge: View {
    let marker: PlanetMarker

    var body: some View {
        Text(marker.displayLabel)
            .font(.caption2.weight(.bold))
            .foregroundColor(marker.tint)
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(marker.tint.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
