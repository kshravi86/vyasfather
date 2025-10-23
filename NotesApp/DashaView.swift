import SwiftUI

struct DashaView: View {
    let mahadashas: [DashaPeriod]
    let planetPositions: [PlanetPosition]
    @State private var expandedMaha: Int? = nil
    @State private var expandedAntar: [Int: Int] = [:]
    @State private var antardashaCache: [Int: [DashaPeriod]] = [:]
    @State private var pratyantarCache: [Int: [Int: [DashaPeriod]]] = [:]
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCurrentBranchOnly: Bool = true

    var body: some View {
        ScrollViewReader { proxy in
        List {
            Section {
                summaryCard()
                Toggle(isOn: $showCurrentBranchOnly.animation(.easeInOut)) {
                    Label("Show current branch only", systemImage: "scope")
                }
                .tint(CosmicTheme.accent)
            }
            .listRowBackground(Color.clear)

            ForEach(visibleMahadashaList().enumerated().map({ ($0.offset, $0.element) }), id: \.0) { (visibleIndex, pair) in
                let (index, maha) = pair
                VStack(alignment: .leading, spacing: 8) {
                    MahadashaRow(
                        maha: maha,
                        position: position(for: maha.lord),
                        isExpanded: expandedMaha == index,
                        onToggle: {
                            withAnimation {
                                if expandedMaha == index {
                                    expandedMaha = nil
                                } else {
                                    expandedMaha = index
                                    if antardashaCache[index] == nil {
                                        antardashaCache[index] = VimshottariDashaCalculator.calculateAntardasha(for: maha)
                                    }
                                }
                            }
                        }
                    )
                    .id("maha-\(index)")

                    if expandedMaha == index {
                        let antardashas = filteredAntardashas(for: index)
                        ForEach(Array(antardashas.enumerated()), id: \.offset) { antarIndex, antar in
                            AntardashaRow(
                                antar: antar,
                                position: position(for: antar.lord),
                                isExpanded: expandedAntar[index] == antarIndex,
                                pratyantars: filteredPratyantars(for: index, antarIndex: antarIndex),
                                onToggle: {
                                    withAnimation {
                                        if expandedAntar[index] == antarIndex {
                                            expandedAntar[index] = nil
                                        } else {
                                            expandedAntar[index] = antarIndex
                                            if pratyantarCache[index] == nil { pratyantarCache[index] = [:] }
                                            if pratyantarCache[index]?[antarIndex] == nil {
                                                pratyantarCache[index]?[antarIndex] = VimshottariDashaCalculator.calculatePratyantar(for: antar)
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.vertical, 6)
                .cardBackground()
            }
        }
        .navigationTitle("Vimshottari Dasha")
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(CosmicTheme.gradient(for: colorScheme))
        .onAppear {
            if let (mi, ai, _) = findCurrentIndices() {
                expandedMaha = mi
                if antardashaCache[mi] == nil {
                    antardashaCache[mi] = VimshottariDashaCalculator.calculateAntardasha(for: mahadashas[mi])
                }
                if let ai = ai { expandedAntar[mi] = ai }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation { proxy.scrollTo("maha-\(mi)", anchor: .center) }
                }
            }
        }
        }
    }

    private func isToday(within p: DashaPeriod) -> Bool {
        let now = Date()
        return (p.startDate ... p.endDate).contains(now)
    }

    private func findCurrentIndices() -> (Int, Int?, Int?)? {
        guard !mahadashas.isEmpty else { return nil }
        let mi = mahadashas.firstIndex(where: { isToday(within: $0) }) ?? (mahadashas.count - 1)
        let antars = VimshottariDashaCalculator.calculateAntardasha(for: mahadashas[mi])
        let ai = antars.firstIndex(where: { isToday(within: $0) })
        var pi: Int? = nil
        if let ai = ai {
            let prats = VimshottariDashaCalculator.calculatePratyantar(for: antars[ai])
            pi = prats.firstIndex(where: { isToday(within: $0) })
        }
        return (mi, ai, pi)
    }

    private func summaryCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Periods").font(.headline)
            if let (mi, ai, pi) = findCurrentIndices() {
                let maha = mahadashas[mi]
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            PlanetChip(name: maha.lord)
                            Spacer()
                            Text(formatDateRange(start: maha.startDate, end: maha.endDate))
                                .font(.caption)
                                .foregroundColor(CosmicTheme.secondaryText)
                        }
                let antars = VimshottariDashaCalculator.calculateAntardasha(for: maha)
                if let ai = ai {
                    let antar = antars[ai]
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        PlanetChip(name: antar.lord)
                                        Spacer()
                                        Text(formatDateRange(start: antar.startDate, end: antar.endDate))
                                            .font(.caption2)
                                            .foregroundColor(CosmicTheme.secondaryText)
                                    }
                }
                if let ai = ai, let pi = pi {
                    let prats = VimshottariDashaCalculator.calculatePratyantar(for: antars[ai])
                    let prat = prats[pi]
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        PlanetChip(name: prat.lord)
                        Spacer()
                        Text(formatDuration(start: prat.startDate, end: prat.endDate))
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.secondaryText)
                    }
                }
            } else {
                Text("No current periods").font(.caption).foregroundColor(CosmicTheme.secondaryText)
            }
        }
        .cardBackground()
    }

    private func position(for lord: String) -> PlanetPosition? {
        let name = lord.lowercased()
        return planetPositions.first { $0.name.lowercased() == name }
    }

    private func visibleMahadashaList() -> [(Int, DashaPeriod)] {
        guard showCurrentBranchOnly, let (mi, _, _) = findCurrentIndices() else {
            return Array(mahadashas.enumerated())
        }
        return [(mi, mahadashas[mi])]
    }

    private func filteredAntardashas(for mahaIndex: Int) -> [DashaPeriod] {
        let list = antardashaCache[mahaIndex] ?? []
        guard showCurrentBranchOnly, let current = findCurrentIndices(), mahaIndex == current.0 else { return list }
        if let ai = current.1, ai < list.count { return [list[ai]] }
        return list
    }

    private func filteredPratyantars(for mahaIndex: Int, antarIndex: Int) -> [DashaPeriod] {
        let list = pratyantarCache[mahaIndex]?[antarIndex] ?? []
        guard showCurrentBranchOnly, let current = findCurrentIndices(), mahaIndex == current.0, antarIndex == current.1 else { return list }
        if let pi = current.2, pi < list.count { return [list[pi]] }
        return list
    }
}

private struct MahadashaRow: View {
    let maha: DashaPeriod
    let position: PlanetPosition?
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                PlanetChip(name: maha.lord)
                Spacer()
                Text(formatDuration(start: maha.startDate, end: maha.endDate))
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct AntardashaRow: View {
    let antar: DashaPeriod
    let position: PlanetPosition?
    let isExpanded: Bool
    let pratyantars: [DashaPeriod]
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: onToggle) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    PlanetChip(name: antar.lord)
                    Spacer()
                    Text(formatDuration(start: antar.startDate, end: antar.endDate))
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.secondaryText)
                }
            }
            .buttonStyle(.plain)
            .padding(.leading, 16)

            if isExpanded {
                ForEach(Array(pratyantars.enumerated()), id: \.offset) { _, pratyantar in
                    PratyantardashaRow(pratyantar: pratyantar, position: nil) // Simplified
                }
            }
        }
    }
}

private struct PratyantardashaRow: View {
    let pratyantar: DashaPeriod
    let position: PlanetPosition?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            PlanetChip(name: pratyantar.lord)
            Spacer()
            Text(formatDuration(start: pratyantar.startDate, end: pratyantar.endDate))
                .font(.caption2)
                .foregroundColor(CosmicTheme.secondaryText)
        }
        .padding(.leading, 32)
    }
}
