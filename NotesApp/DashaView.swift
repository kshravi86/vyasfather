import SwiftUI

struct DashaView: View {
    let mahadashas: [DashaPeriod]
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
                .tint(Color("AccentColor"))
            }
            .listRowBackground(Color.clear)

            ForEach(visibleMahadashaList().enumerated().map({ ($0.offset, $0.element) }), id: \.0) { (visibleIndex, pair) in
                let (index, maha) = pair
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: {
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
                    }) {
                        HStack {
                            PlanetChip(name: maha.lord)
                            Spacer()
                            Text(formatDateRange(start: maha.startDate, end: maha.endDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    if expandedMaha == index {
                        let antardashas = filteredAntardashas(for: index)

                        ForEach(Array(antardashas.enumerated()), id: \.offset) { antarIndex, antar in
                            VStack(alignment: .leading, spacing: 4) {
                                Button(action: {
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
                                }) {
                                    HStack {
                                        Text(antar.lord)
                                            .font(.subheadline)
                                        Spacer()
                                        Text(formatDateRange(start: antar.startDate, end: antar.endDate))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 16)

                                if expandedAntar[index] == antarIndex {
                                    let pratyantars = filteredPratyantars(for: index, antarIndex: antarIndex)

                                    ForEach(Array(pratyantars.enumerated()), id: \.offset) { _, pratyantar in
                                        HStack {
                                            Text(pratyantar.lord)
                                                .font(.caption)
                                            Spacer()
                                            Text(formatDateRange(start: pratyantar.startDate, end: pratyantar.endDate))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.leading, 32)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
                .cardBackground()
                .id("maha-\(index)")
            }
        }
        .navigationTitle("Vimshottari Dasha")
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(WaterTheme.gradient(for: colorScheme))
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

    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
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
                HStack { PlanetChip(name: maha.lord); Spacer(); Text(formatDateRange(start: maha.startDate, end: maha.endDate)).font(.caption).foregroundColor(.secondary) }
                let antars = VimshottariDashaCalculator.calculateAntardasha(for: maha)
                if let ai = ai {
                    let antar = antars[ai]
                    HStack { Text(antar.lord).font(.subheadline); Spacer(); Text(formatDateRange(start: antar.startDate, end: antar.endDate)).font(.caption2).foregroundColor(.secondary) }
                }
                if let ai = ai, let pi = pi {
                    let prats = VimshottariDashaCalculator.calculatePratyantar(for: antars[ai])
                    let prat = prats[pi]
                    HStack { Text(prat.lord).font(.caption); Spacer(); Text(formatDateRange(start: prat.startDate, end: prat.endDate)).font(.caption2).foregroundColor(.secondary) }
                }
            } else {
                Text("No current periods").font(.caption).foregroundColor(.secondary)
            }
        }
        .cardBackground()
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
