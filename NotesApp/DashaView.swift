import SwiftUI

struct DashaView: View {
    let mahadashas: [DashaPeriod]
    let planetPositions: [PlanetPosition]
    @State private var expandedMaha: Int? = nil
    @State private var expandedAntar: [Int: Int] = [:]
    @State private var expandedPratyantar: [Int: [Int: Int]] = [:]
    @State private var antardashaCache: [Int: [DashaPeriod]] = [:]
    @State private var pratyantarCache: [Int: [Int: [DashaPeriod]]] = [:]
    @State private var sookshmaCache: [Int: [Int: [Int: [DashaPeriod]]]] = [:]
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCurrentBranchOnly: Bool = true

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 20) {
                    // Header section
                    headerSection()
                    
                    // Current periods summary card
                    enhancedSummaryCard()
                    
                    // Controls section
                    controlsSection()
                    
                    // Dasha periods
                    LazyVStack(spacing: 16) {
                        ForEach(visibleMahadashaList().enumerated().map({ ($0.offset, $0.element) }), id: \.0) { (visibleIndex, pair) in
                            let (index, maha) = pair
                            enhancedMahadashaCard(
                                index: index,
                                maha: maha,
                                proxy: proxy
                            )
                            .id("maha-\(index)")
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Vimshottari Dasha")
            .navigationBarTitleDisplayMode(.large)
            .background(CosmicTheme.gradient(for: colorScheme))
            .onAppear {
                if let (mi, ai, _) = findCurrentIndices() {
                    expandedMaha = mi
                    if antardashaCache[mi] == nil {
                        antardashaCache[mi] = VimshottariDashaCalculator.calculateAntardasha(for: mahadashas[mi])
                    }
                    if let ai = ai { expandedAntar[mi] = ai }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.8)) { 
                            proxy.scrollTo("maha-\(mi)", anchor: .center) 
                        }
                    }
                }
            }
        }
    }

    private func isToday(within p: DashaPeriod) -> Bool {
        let now = Date()
        return (p.startDate ... p.endDate).contains(now)
    }

    private func findCurrentIndices() -> (Int, Int?, Int?, Int?)? {
        guard !mahadashas.isEmpty else { return nil }
        let mi = mahadashas.firstIndex(where: { isToday(within: $0) }) ?? (mahadashas.count - 1)
        let antars = VimshottariDashaCalculator.calculateAntardasha(for: mahadashas[mi])
        let ai = antars.firstIndex(where: { isToday(within: $0) })
        var pi: Int? = nil
        var si: Int? = nil
        if let ai = ai {
            let prats = VimshottariDashaCalculator.calculatePratyantar(for: antars[ai])
            pi = prats.firstIndex(where: { isToday(within: $0) })
            if let pi = pi {
                let sookshmas = VimshottariDashaCalculator.calculateSookshma(for: prats[pi])
                si = sookshmas.firstIndex(where: { isToday(within: $0) })
            }
        }
        return (mi, ai, pi, si)
    }
    
    @ViewBuilder
    private func headerSection() -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "hourglass.clock")
                    .font(.title2)
                    .foregroundColor(CosmicTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vimshottari Dasha")
                        .font(.title3.bold())
                        .foregroundColor(CosmicTheme.text)
                    Text("Planetary periods and their influences")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func enhancedSummaryCard() -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "clock.badge.checkmark")
                        .font(.title3)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Periods")
                        .font(.headline)
                        .foregroundColor(CosmicTheme.text)
                    Text("Active planetary influences")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText)
                }
                Spacer()
            }
            
            if let (mi, ai, pi, si) = findCurrentIndices() {
                let maha = mahadashas[mi]
                
                VStack(spacing: 16) {
                    // Mahadasha
                    currentPeriodRow(
                        title: "Mahadasha",
                        period: maha,
                        level: 0,
                        color: PlanetStyle.color(for: maha.lord)
                    )
                    
                    let antars = VimshottariDashaCalculator.calculateAntardasha(for: maha)
                    if let ai = ai {
                        let antar = antars[ai]
                        currentPeriodRow(
                            title: "Antardasha",
                            period: antar,
                            level: 1,
                            color: PlanetStyle.color(for: antar.lord)
                        )
                        
                        if let pi = pi {
                            let prats = VimshottariDashaCalculator.calculatePratyantar(for: antars[ai])
                            let prat = prats[pi]
                            currentPeriodRow(
                                title: "Pratyantardasha",
                                period: prat,
                                level: 2,
                                color: PlanetStyle.color(for: prat.lord)
                            )
                            
                            if let si = si {
                                let sookshmas = VimshottariDashaCalculator.calculateSookshma(for: prats[pi])
                                let sookshma = sookshmas[si]
                                currentPeriodRow(
                                    title: "Sookshma",
                                    period: sookshma,
                                    level: 3,
                                    color: PlanetStyle.color(for: sookshma.lord)
                                )
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.trianglehead.clockwise.rotate.90")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("No Active Periods")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.secondaryText)
                    Text("Check your birth details")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.green.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.green.opacity(0.1), radius: 8, x: 0, y: 4)
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func currentPeriodRow(title: String, period: DashaPeriod, level: Int, color: Color) -> some View {
        HStack(spacing: 12) {
            // Level indicator
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index <= level ? color : Color.white.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                HStack(spacing: 8) {
                    PlanetChip(name: period.lord, isCompact: false)
                    Spacer()
                }
            }
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDateRange(start: period.startDate, end: period.endDate))
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                Text(formatDuration(from: period.startDate, to: period.endDate))
                    .font(.caption2)
                    .foregroundColor(color)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func controlsSection() -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Display Options")
                        .font(.headline)
                        .foregroundColor(CosmicTheme.text)
                    Text("Customize your view")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText)
                }
                Spacer()
            }
            
            Toggle(isOn: $showCurrentBranchOnly.animation(.easeInOut)) {
                HStack(spacing: 12) {
                    Image(systemName: showCurrentBranchOnly ? "scope" : "list.bullet")
                        .foregroundColor(showCurrentBranchOnly ? .green : .orange)
                    Text("Show current branch only")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.text)
                }
            }
            .tint(CosmicTheme.accent)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func enhancedMahadashaCard(index: Int, maha: DashaPeriod, proxy: ScrollViewReader) -> some View {
        let planetColor = PlanetStyle.color(for: maha.lord)
        let isExpanded = expandedMaha == index
        let isCurrent = isToday(within: maha)
        
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
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
                HStack(spacing: 16) {
                    // Planet chip with enhanced styling
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(planetColor.opacity(0.2))
                                .frame(width: 50, height: 50)
                            Image(systemName: PlanetStyle.icon(for: maha.lord))
                                .font(.title2)
                                .foregroundColor(planetColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(maha.lord)
                                .font(.headline.bold())
                                .foregroundColor(CosmicTheme.text)
                            Text("Mahadasha")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatDateRange(start: maha.startDate, end: maha.endDate))
                            .font(.caption)
                            .foregroundColor(CosmicTheme.secondaryText)
                        
                        if isCurrent {
                            TagBadge(text: "Current", color: .green)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(planetColor)
                    }
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                let antardashas = filteredAntardashas(for: index)
                if antardashas.isEmpty {
                    Text("No antardasha data available")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText)
                        .padding(.vertical, 8)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(antardashas.enumerated()), id: \.offset) { antarIndex, antar in
                            enhancedAntardashaRow(
                                mahaIndex: index,
                                antarIndex: antarIndex,
                                antar: antar
                            )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isCurrent ? 0.12 : 0.08),
                            Color.white.opacity(isCurrent ? 0.06 : 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    planetColor.opacity(isCurrent ? 0.5 : 0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isCurrent ? 2 : 1
                        )
                )
                .shadow(color: planetColor.opacity(isCurrent ? 0.2 : 0.1), radius: isCurrent ? 12 : 8, x: 0, y: isCurrent ? 6 : 4)
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
    
    @ViewBuilder
    private func enhancedAntardashaRow(mahaIndex: Int, antarIndex: Int, antar: DashaPeriod) -> some View {
        let planetColor = PlanetStyle.color(for: antar.lord)
        let isExpanded = expandedAntar[mahaIndex] == antarIndex
        let isCurrent = isToday(within: antar)
        
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if expandedAntar[mahaIndex] == antarIndex {
                        expandedAntar[mahaIndex] = nil
                    } else {
                        expandedAntar[mahaIndex] = antarIndex
                        if pratyantarCache[mahaIndex] == nil { pratyantarCache[mahaIndex] = [:] }
                        if pratyantarCache[mahaIndex]?[antarIndex] == nil {
                            pratyantarCache[mahaIndex]?[antarIndex] = VimshottariDashaCalculator.calculatePratyantar(for: antar)
                        }
                    }
                }
            }) {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(planetColor.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: PlanetStyle.icon(for: antar.lord))
                                .font(.caption)
                                .foregroundColor(planetColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(antar.lord)
                                .font(.subheadline.bold())
                                .foregroundColor(CosmicTheme.text)
                            Text("Antardasha")
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatDateRange(start: antar.startDate, end: antar.endDate))
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.secondaryText)
                        
                        HStack(spacing: 4) {
                            if isCurrent {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 6, height: 6)
                            }
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundColor(planetColor)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                let pratyantars = filteredPratyantars(for: mahaIndex, antarIndex: antarIndex)
                if !pratyantars.isEmpty {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(pratyantars.enumerated()), id: \.offset) { pratyantarIndex, pratyantar in
                            enhancedPratyantarRow(
                                mahaIndex: mahaIndex,
                                antarIndex: antarIndex,
                                pratyantarIndex: pratyantarIndex,
                                pratyantar: pratyantar
                            )
                        }
                    }
                    .padding(.leading, 20)
                }
            }
        }
        .padding(.leading, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(planetColor.opacity(isCurrent ? 0.08 : 0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(planetColor.opacity(isCurrent ? 0.3 : 0.15), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func enhancedPratyantarRow(mahaIndex: Int, antarIndex: Int, pratyantarIndex: Int, pratyantar: DashaPeriod) -> some View {
        let planetColor = PlanetStyle.color(for: pratyantar.lord)
        let isExpanded = expandedPratyantar[mahaIndex]?[antarIndex] == pratyantarIndex
        let isCurrent = isToday(within: pratyantar)
        
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedPratyantar[mahaIndex]?[antarIndex] = nil
                    } else {
                        if expandedPratyantar[mahaIndex] == nil { expandedPratyantar[mahaIndex] = [:] }
                        expandedPratyantar[mahaIndex]?[antarIndex] = pratyantarIndex
                        
                        if sookshmaCache[mahaIndex] == nil { sookshmaCache[mahaIndex] = [:] }
                        if sookshmaCache[mahaIndex]?[antarIndex] == nil { sookshmaCache[mahaIndex]?[antarIndex] = [:] }
                        if sookshmaCache[mahaIndex]?[antarIndex]?[pratyantarIndex] == nil {
                            sookshmaCache[mahaIndex]?[antarIndex]?[pratyantarIndex] = VimshottariDashaCalculator.calculateSookshma(for: pratyantar)
                        }
                    }
                }
            }) {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(planetColor)
                            .frame(width: 8, height: 8)
                        
                        Text(pratyantar.lord)
                            .font(.caption.bold())
                            .foregroundColor(CosmicTheme.text)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(formatDateRange(start: pratyantar.startDate, end: pratyantar.endDate))
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.secondaryText)
                        
                        if isCurrent {
                            Circle()
                                .fill(.green)
                                .frame(width: 4, height: 4)
                        }
                        
                        Image(systemName: isExpanded ? "minus" : "plus")
                            .font(.caption2)
                            .foregroundColor(planetColor)
                    }
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                let sookshmas = sookshmaCache[mahaIndex]?[antarIndex]?[pratyantarIndex] ?? []
                if !sookshmas.isEmpty {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(sookshmas.enumerated()), id: \.offset) { _, sookshma in
                            enhancedSookshmaRow(sookshma: sookshma)
                        }
                    }
                    .padding(.leading, 16)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(planetColor.opacity(isCurrent ? 0.06 : 0.02))
        )
    }
    
    @ViewBuilder
    private func enhancedSookshmaRow(sookshma: DashaPeriod) -> some View {
        let planetColor = PlanetStyle.color(for: sookshma.lord)
        let isCurrent = isToday(within: sookshma)
        
        HStack(spacing: 8) {
            Circle()
                .fill(planetColor)
                .frame(width: 6, height: 6)
            
            Text(sookshma.lord)
                .font(.caption2)
                .foregroundColor(CosmicTheme.text)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(formatDateRange(start: sookshma.startDate, end: sookshma.endDate))
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.secondaryText)
                
                if isCurrent {
                    Circle()
                        .fill(.green)
                        .frame(width: 3, height: 3)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(planetColor.opacity(isCurrent ? 0.05 : 0.01))
        )
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let interval = end.timeIntervalSince(start)
        let years = Int(interval / (365.25 * 24 * 3600))
        let months = Int((interval.truncatingRemainder(dividingBy: 365.25 * 24 * 3600)) / (30.44 * 24 * 3600))
        
        if years > 0 {
            return "\(years)y \(months)m"
        } else {
            return "\(months)m"
        }
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
