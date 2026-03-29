import SwiftUI

private struct PlanetMarker: Identifiable {
    let id = UUID()
    let label: String
    let tint: Color
    let isRetrograde: Bool
    let isAscendant: Bool

    var displayLabel: String {
        if isAscendant {
            return "La"
        }
        return isRetrograde ? "\(label)R" : label
    }
}

private struct ChartLegendItem: Identifiable {
    let id = UUID()
    let title: String
    let tint: Color
}

struct SouthIndianChartView: View {
    let planetPositions: [PlanetPosition]
    let ascendant: (sign: String, deg: Int, min: Int)?
    var title: String = "South Indian Chart"
    var subtitle: String = "D1 Rasi placement"

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

    private var hasChartData: Bool {
        !planetPositions.isEmpty || ascendant != nil
    }

    private var legendItems: [ChartLegendItem] {
        [
            ChartLegendItem(title: "La Ascendant", tint: CosmicTheme.accent),
            ChartLegendItem(title: "R Retrograde", tint: CosmicTheme.rose),
            ChartLegendItem(title: "\(planetPositions.count) planets loaded", tint: CosmicTheme.accentSoft)
        ]
    }

    private var markersBySign: [String: [PlanetMarker]] {
        var map: [String: [PlanetMarker]] = [:]
        if let asc = ascendant {
            map[asc.sign, default: []].append(
                PlanetMarker(
                    label: "La",
                    tint: CosmicTheme.accent,
                    isRetrograde: false,
                    isAscendant: true
                )
            )
        }

        let byName = Dictionary(uniqueKeysWithValues: planetPositions.map { ($0.name, $0) })
        for name in planetOrder {
            guard let pos = byName[name] else { continue }
            let label = planetLabels[name] ?? String(name.prefix(2))
            let tint = PlanetStyle.color(for: name)
            let isRetro = pos.retrograde
            map[pos.sign, default: []].append(
                PlanetMarker(
                    label: label,
                    tint: tint,
                    isRetrograde: isRetro,
                    isAscendant: false
                )
            )
        }
        return map
    }

    var body: some View {
        ZStack {
            CosmicBackgroundView()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    headerView

                    if !hasChartData {
                        emptyStateCard
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(legendItems) { item in
                                    legendChip(item)
                                }
                            }
                            .padding(.trailing, 4)
                        }

                        chartGrid
                            .frame(maxWidth: 480)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 90)
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CHART VIEW")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundColor(CosmicTheme.secondaryText)

                    Text(title)
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundColor(CosmicTheme.starlight)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.secondaryText)
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(CosmicTheme.accent.opacity(0.16))
                        .frame(width: 56, height: 56)

                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(CosmicTheme.accent)
                }
            }

            ViewThatFits {
                HStack(spacing: 10) {
                    if let ascendant {
                        headerPill(
                            icon: "arrow.up.right.diamond.fill",
                            title: "\(ascendant.sign) rising",
                            tint: CosmicTheme.accent
                        )
                    }

                    headerPill(
                        icon: "sparkles",
                        title: "\(planetPositions.count) grahas",
                        tint: CosmicTheme.accentSoft
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    if let ascendant {
                        headerPill(
                            icon: "arrow.up.right.diamond.fill",
                            title: "\(ascendant.sign) rising",
                            tint: CosmicTheme.accent
                        )
                    }

                    headerPill(
                        icon: "sparkles",
                        title: "\(planetPositions.count) grahas",
                        tint: CosmicTheme.accentSoft
                    )
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(CosmicTheme.heroGradient.opacity(0.22))
        )
        .cosmicGlass(cornerRadius: 30, tint: CosmicTheme.accent, highlightOpacity: 0.14)
    }

    private var chartGrid: some View {
        let gridSize = 4
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: gridSize)
        return ZStack {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(0..<(gridSize * gridSize), id: \.self) { index in
                    let row = index / gridSize
                    let col = index % gridSize
                    let sign = grid[row][col]
                    ChartCell(
                        sign: sign,
                        signLabel: sign.map { signAbbrev[$0] ?? $0 } ?? "",
                        markers: sign.map { markersBySign[$0] ?? [] } ?? [],
                        isAscendantSign: sign == ascendant?.sign
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                }
            }

            centerPlaque
                .allowsHitTesting(false)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .cosmicGlass(cornerRadius: 30, tint: CosmicTheme.accent, highlightOpacity: 0.12)
    }

    private var centerPlaque: some View {
        VStack(spacing: 6) {
            Text("D1")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text("Rasi Chart")
                .font(.caption.weight(.semibold))
                .foregroundColor(CosmicTheme.secondaryText)

            if let ascendant {
                Text(ascendant.sign.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundColor(CosmicTheme.accent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private var emptyStateCard: some View {
        Text("Enter birth details to plot the D1 chart and highlight the ascendant sign.")
            .font(.caption)
            .foregroundColor(CosmicTheme.secondaryText)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cosmicGlass(cornerRadius: 20, tint: Color.white.opacity(0.25), highlightOpacity: 0.08)
    }

    private func headerPill(icon: String, title: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundColor(tint)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(tint.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private func legendChip(_ item: ChartLegendItem) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(item.tint)
                .frame(width: 8, height: 8)

            Text(item.title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.09))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }
}

private struct ChartCell: View {
    let sign: String?
    let signLabel: String
    let markers: [PlanetMarker]
    let isAscendantSign: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(isAscendantSign ? CosmicTheme.accent.opacity(0.12) : Color.white.opacity(0.08))

            Rectangle()
                .stroke(
                    isAscendantSign ? CosmicTheme.accent.opacity(0.40) : Color.white.opacity(0.14),
                    lineWidth: 1
                )

            if sign != nil {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Text(signLabel)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(CosmicTheme.secondaryText)

                        if isAscendantSign {
                            Text("ASC")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(CosmicTheme.accent)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(CosmicTheme.accent.opacity(0.12))
                                )
                        }
                    }

                    if markers.isEmpty {
                        Text("Empty")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.secondaryText.opacity(0.65))
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

                    Spacer(minLength: 0)
                }
                .padding(8)
            }
        }
        .background(Color.white.opacity(0.05))
    }
}

private struct PlanetBadge: View {
    let marker: PlanetMarker

    var body: some View {
        Text(marker.displayLabel)
            .font(.caption2.weight(.black))
            .foregroundColor(marker.isAscendant ? CosmicTheme.backgroundDeep : marker.tint)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(marker.tint.opacity(marker.isAscendant ? 0.82 : 0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(marker.tint.opacity(marker.isAscendant ? 0.18 : 0.28), lineWidth: 1)
                    )
            )
    }
}
