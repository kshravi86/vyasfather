import SwiftUI
import MapKit
#if canImport(UIKit)
import UIKit
#endif

/// Root view that captures birth inputs, runs the planetary calculator, and
/// renders the tabbed dashboards/readouts around that data.
struct ContentView: View {
    // Inputs
    @State private var dateOfBirth: Date = Calendar.current.date(from: DateComponents(year: 1993, month: 5, day: 18)) ?? Date()
    @State private var timeOfBirth: Date = {
        var comps = DateComponents()
        comps.hour = 22
        comps.minute = 30
        // Use today's date as base; picker uses only time component
        let base = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(bySettingHour: comps.hour ?? 22, minute: comps.minute ?? 30, second: 0, of: base) ?? Date()
    }()
    @StateObject private var searchManager = LocationSearchManager()

    // Selection result
    @State private var selectedTitle: String = "Bengaluru"
    @State private var selectedCoordinate: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)
    @State private var selectedState: String = ""
    @State private var selectedCountry: String = ""
    @State private var selectedTimeZone: TimeZone? = nil
    @State private var submitted: Bool = true
    @State private var planetPositions: [PlanetPosition] = []
    @State private var panchanga: PanchangaResultModel? = nil
    private let calculator = PlanetaryCalculator()
    @State private var calcError: String? = nil
    @State private var toast: Toast? = nil
    @State private var lastSyncedAt: Date? = nil

    // Partner inputs for matchmaking
    @State private var primaryGender: ChartGender = .male
    @State private var partnerGender: ChartGender = .female
    @State private var partnerDateOfBirth: Date = Calendar.current.date(from: DateComponents(year: 1995, month: 8, day: 10)) ?? Date()
    @State private var partnerTimeOfBirth: Date = Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: Date()) ?? Date()
    @StateObject private var partnerSearchManager = LocationSearchManager()
    @State private var partnerSelectedTitle: String = ""
    @State private var partnerSelectedCoordinate: CLLocationCoordinate2D? = nil
    @State private var partnerSelectedState: String = ""
    @State private var partnerSelectedCountry: String = ""
    @State private var partnerSelectedTimeZone: TimeZone? = nil
    @State private var partnerSubmitted: Bool = false
    @State private var partnerPlanetPositions: [PlanetPosition] = []
    private let partnerCalculator = PlanetaryCalculator()
    @State private var partnerCalcError: String? = nil
    @State private var partnerLastSyncedAt: Date? = nil

    @State private var selectedTab: Int = 0
    private let tabsMeta: [TabMetadata] = [
        TabMetadata(id: 0, title: "Birth", icon: "person.crop.circle", accent: .mint),
        TabMetadata(id: 13, title: "Chart", icon: "square.grid.2x2", accent: .yellow),
        TabMetadata(id: 1, title: "Dasha", icon: "moon.stars.fill", accent: .purple),
        TabMetadata(id: 2, title: "Yogi", icon: "sun.max.trianglebadge.exclamationmark", accent: .orange),
        TabMetadata(id: 3, title: "Uttama", icon: "seal.fill", accent: .blue),
        TabMetadata(id: 4, title: "Jaimini", icon: "text.badge.star", accent: .pink),
        TabMetadata(id: 5, title: "Panchanga", icon: "calendar", accent: .teal),
        TabMetadata(id: 6, title: "Ishta", icon: "flame.fill", accent: .red),
        TabMetadata(id: 7, title: "D9", icon: "square.grid.3x3", accent: .indigo),
        TabMetadata(id: 8, title: "D7", icon: "square.grid.3x2", accent: .cyan),
        TabMetadata(id: 9, title: "Lagnas", icon: "clock.badge.checkmark", accent: .yellow),
        TabMetadata(id: 10, title: "64/22", icon: "circle.hexagongrid", accent: .gray),
        TabMetadata(id: 11, title: "Pushkara", icon: "leaf.circle", accent: .green),
        TabMetadata(id: 12, title: "Match", icon: "heart.circle.fill", accent: .pink)
    ]

    private struct CosmicInsight: Identifiable, Equatable {
        let id: String
        let title: String
        let detail: String
        let icon: String
        let tint: Color
    }

    private struct GeoCoordinate: Equatable {
        let latitude: Double
        let longitude: Double
    }

    private struct RecomputeInput: Equatable {
        let date: Date
        let time: Date
        let coordinate: GeoCoordinate?
        let timeZoneId: String?
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    var body: some View {
        ZStack {
            CosmicBackgroundView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                cosmicTopBar

                if selectedTab == 0 {
                    cosmicDashboard
                }
                
                // Current Tab View
                TabView(selection: $selectedTab) {
                    BirthInfoView(
                        dateOfBirth: $dateOfBirth,
                        timeOfBirth: $timeOfBirth,
                        searchManager: searchManager,
                        selectedTitle: $selectedTitle,
                        selectedCoordinate: $selectedCoordinate,
                        selectedState: $selectedState,
                        selectedCountry: $selectedCountry,
                        selectedTimeZone: $selectedTimeZone,
                        submitted: $submitted,
                        planetPositions: $planetPositions,
                        calculator: calculator,
                        calcError: $calcError,
                        toast: $toast,
                        onRecompute: recomputePlanets
                    )
                    .tag(0)

                    SouthIndianChartView(
                        planetPositions: planetPositions,
                        ascendant: calculator.ascendant
                    )
                    .tag(13)

                    DashaTabView(
                        dateOfBirth: dateOfBirth,
                        timeOfBirth: timeOfBirth,
                        coordinate: selectedCoordinate,
                        planetPositions: planetPositions
                    )
                    .tag(1)

                    YogiTabView(planetPositions: planetPositions)
                    .tag(2)

                    UttamaTabView(
                        planetPositions: planetPositions,
                        ascendant: calculator.ascendant
                    )
                    .tag(3)

                    JaiminiTabView(
                        planetPositions: planetPositions,
                        houses: calculator.houses
                    )
                    .tag(4)

                    PanchangaTabView(
                        dateOfBirth: dateOfBirth,
                        timeOfBirth: timeOfBirth,
                        coordinate: selectedCoordinate,
                        planetPositions: planetPositions
                    )
                    .tag(5)

                    IshtaDevataTabView(planetPositions: planetPositions, ascendant: calculator.ascendant)
                    .tag(6)

                    NavamshaLordsTabView(
                        planetPositions: planetPositions,
                        ascendant: calculator.ascendant
                    )
                    .tag(7)

                    SaptamshaLordsTabView(
                        planetPositions: planetPositions,
                        ascendant: calculator.ascendant
                    )
                    .tag(8)

                    LagnasTabView(
                        dateOfBirth: dateOfBirth,
                        timeOfBirth: timeOfBirth,
                        coordinate: selectedCoordinate,
                        planetPositions: planetPositions,
                        ascendant: calculator.ascendant
                    )
                    .tag(9)

                    SixtyFourTwentyTwoTabView(
                        ascendant: calculator.ascendant,
                        planetPositions: planetPositions
                    )
                    .tag(10)

                    PushkaraTabView(planetPositions: planetPositions, ascendant: calculator.ascendant)
                    .tag(11)

                    MatchmakingTabView(
                        primaryPositions: planetPositions,
                        primaryAscendant: calculator.ascendant,
                        primaryGender: $primaryGender,
                        partnerGender: $partnerGender,
                        partnerDateOfBirth: $partnerDateOfBirth,
                        partnerTimeOfBirth: $partnerTimeOfBirth,
                        partnerSearchManager: partnerSearchManager,
                        partnerSelectedTitle: $partnerSelectedTitle,
                        partnerSelectedCoordinate: $partnerSelectedCoordinate,
                        partnerSelectedState: $partnerSelectedState,
                        partnerSelectedCountry: $partnerSelectedCountry,
                        partnerSelectedTimeZone: $partnerSelectedTimeZone,
                        partnerSubmitted: $partnerSubmitted,
                        partnerPlanetPositions: $partnerPlanetPositions,
                        partnerAscendant: partnerCalculator.ascendant,
                        partnerCalcError: $partnerCalcError,
                        partnerLastSyncedAt: $partnerLastSyncedAt,
                        matchResult: matchResult,
                        onRecompute: recomputePartnerPlanets
                    )
                    .tag(12)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }

            // Floating Dock
            VStack {
                Spacer()
                MainTabView(selectedTab: $selectedTab, tabsMeta: tabsMeta)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
            .ignoresSafeArea(.keyboard)
        }
        .tint(CosmicTheme.accent)
        .onAppear {
            if let requestedTab = requestedTabIndexFromArgs() {
                selectedTab = requestedTab
            }
            recomputePlanets()
        }
        .onChange(of: recomputeInput) { _ in
            recomputePlanets()
        }
        .onChange(of: partnerRecomputeInput) { _ in
            recomputePartnerPlanets()
        }
        .toast($toast)
    }

    private func requestedTabIndexFromArgs() -> Int? {
        let args = ProcessInfo.processInfo.arguments
        guard let tabIndex = args.firstIndex(of: "--tab"), tabIndex + 1 < args.count else {
            return nil
        }
        let value = args[tabIndex + 1].lowercased()
        switch value {
        case "birth": return 0
        case "chart", "d1", "rasi", "rashi": return 13
        case "dasha": return 1
        case "yogi": return 2
        case "uttama": return 3
        case "jaimini": return 4
        case "panchanga": return 5
        case "ishtadevta", "ishta", "ishta-devata": return 6
        case "d9": return 7
        case "d7": return 8
        case "lagnas": return 9
        case "sixtyfourtwentytwo", "64/22", "6422": return 10
        case "pushkara": return 11
        case "match", "matchmaking", "compatibility": return 12
        default: return nil
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }

    private var cosmicTopBar: some View {
        HStack {
            Spacer()
            
            Button {
                handleManualResync()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(12)
                    .background(Circle().fill(CosmicTheme.midnight.opacity(0.5)))
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private var cosmicDashboard: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Hero Header
            VStack(alignment: .leading, spacing: 8) {
                Text(greetingText)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundColor(CosmicTheme.starlight)
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                    Text(selectedTitle)
                    Text("•")
                    Text(Self.dateFormatter.string(from: dateOfBirth))
                }
                .font(.subheadline)
                .foregroundColor(CosmicTheme.secondaryText)
            }
            .padding(.horizontal, 4)

            // Panchanga Grid (Clean 2x2)
            if let p = panchanga {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statCard(title: "Tithi", value: p.tithi, icon: "moonphase.first.quarter", color: .mint)
                    statCard(title: "Nakshatra", value: p.nakshatra, icon: "star.fill", color: .cyan)
                    statCard(title: "Yoga", value: p.yoga, icon: "figure.mind.and.body", color: .purple)
                    statCard(title: "Vara", value: p.vara, icon: "sun.max.fill", color: .orange)
                }
            } else {
                HStack {
                    Spacer()
                    Text("Calculating cosmic time...")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText)
                    Spacer()
                }
                .padding(.vertical, 20)
            }
            
            // Planetary Insights (Horizontal Scroll)
            if !currentInsights.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(currentInsights) { insight in
                            insightChip(insight)
                        }
                    }
                }
            }
        }
        .padding(20)
        .padding(.top, 10) // Extra top padding
        .padding(.horizontal, 16)
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundColor(CosmicTheme.secondaryText)
                    .tracking(1)
            }
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(CosmicTheme.midnight.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }

    private var actionStrip: some View {
        EmptyView() // Deprecated
    }

    private var activeTabMetadata: TabMetadata {
        tabsMeta.first(where: { $0.id == selectedTab }) ?? tabsMeta[0]
    }

    private var statusBadge: (text: String, color: Color) {
        if calcError != nil {
            return ("ERROR", .pink)
        }
        if planetPositions.isEmpty {
            return ("SETUP", .orange)
        }
        return ("SYNCED", .green)
    }

    private var activeCoordinate: GeoCoordinate? {
        guard let coordinate = selectedCoordinate else { return nil }
        return GeoCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    private var partnerActiveCoordinate: GeoCoordinate? {
        guard let coordinate = partnerSelectedCoordinate else { return nil }
        return GeoCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    /// Bundled inputs that trigger a recalculation when any of them change.
    private var recomputeInput: RecomputeInput {
        RecomputeInput(
            date: dateOfBirth,
            time: timeOfBirth,
            coordinate: activeCoordinate,
            timeZoneId: selectedTimeZone?.identifier
        )
    }

    private var partnerRecomputeInput: RecomputeInput {
        RecomputeInput(
            date: partnerDateOfBirth,
            time: partnerTimeOfBirth,
            coordinate: partnerActiveCoordinate,
            timeZoneId: partnerSelectedTimeZone?.identifier
        )
    }

    private var matchResult: MatchCompatibility? {
        guard let primaryProfile = MatchmakingEngine.profile(from: planetPositions, ascendant: calculator.ascendant),
              let partnerProfile = MatchmakingEngine.profile(from: partnerPlanetPositions, ascendant: partnerCalculator.ascendant) else {
            return nil
        }
        return MatchmakingEngine.evaluate(
            primary: primaryProfile,
            partner: partnerProfile,
            primaryGender: primaryGender,
            partnerGender: partnerGender
        )
    }

    private var summaryInput: DashboardSummaryInput {
        DashboardSummaryInput(
            planetPositions: planetPositions,
            ascendant: calculator.ascendant,
            dateOfBirth: dateOfBirth,
            timeOfBirth: timeOfBirth,
            selectedTitle: selectedTitle,
            selectedState: selectedState,
            selectedCountry: selectedCountry,
            coordinate: selectedCoordinate,
            calcError: calcError,
            lastSyncedAt: lastSyncedAt
        )
    }

    private var locationDescriptor: String {
        DashboardSummaryBuilder.locationDescriptor(for: summaryInput)
    }

    private var coordinateDescriptor: String {
        DashboardSummaryBuilder.coordinateDescriptor(for: summaryInput)
    }

    private var syncBadgeText: String {
        DashboardSummaryBuilder.syncBadgeText(for: summaryInput)
    }

    private var syncBadgeDetail: String {
        DashboardSummaryBuilder.syncBadgeDetail(
            for: summaryInput,
            now: Date(),
            relativeFormatter: Self.relativeFormatter
        )
    }

    private var diagnosticsSubtitle: String {
        if let calcError {
            return calcError
        }
        if calculator.epheFilesCount > 0 {
            return "\(calculator.epheFilesCount) Swiss files"
        }
        return "Swiss files missing"
    }

    private var statDescriptors: [DashboardStatDescriptor] {
        DashboardSummaryBuilder.statDescriptors(
            for: summaryInput,
            dateFormatter: Self.dateFormatter,
            timeFormatter: Self.timeFormatter,
            relativeFormatter: Self.relativeFormatter,
            now: Date()
        )
    }

    private var heroLine: String {
        DashboardSummaryBuilder.heroLine(for: summaryInput)
    }


    private var syncIconName: String {
        planetPositions.isEmpty ? "antenna.radiowaves.left.and.right" : "checkmark.seal.fill"
    }

    private var syncTint: Color {
        planetPositions.isEmpty ? .orange : .green
    }

    private var statColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 140), spacing: 16),
            GridItem(.flexible(minimum: 140), spacing: 16)
        ]
    }

    private var heroHeader: some View {
        EmptyView() // Deprecated
    }

    private var statsGrid: some View {
        EmptyView() // Deprecated
    }

    private var insightsSection: some View {
        EmptyView() // Deprecated
    }

    private func infoChip(icon: String, title: String, subtitle: String?, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(tint)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .cosmicGlass(cornerRadius: 20, tint: tint.opacity(0.8), highlightOpacity: 0.15)
    }

    private var insightPlaceholder: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No planetary data yet")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
            Text("Enter birth details in the Birth tab to unlock personalised yogas, dashas and auspicious timings.")
                .font(.caption)
                .foregroundColor(CosmicTheme.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.white.opacity(0.01)
        )
        .cosmicGlass(cornerRadius: 22, tint: Color.white.opacity(0.3), highlightOpacity: 0.1)
    }

    private func errorCallout(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(12)
        .cosmicGlass(cornerRadius: 18, tint: .yellow, highlightOpacity: 0.2)
    }

    /// Synthesised highlight list shown at the top of the dashboard for quick glance.
    private var currentInsights: [CosmicInsight] {
        var list: [CosmicInsight] = []
        if let asc = calculator.ascendant {
            list.append(CosmicInsight(
                id: "ascendant",
                title: "Ascendant",
                detail: AngleFormatter.describe(sign: asc.sign, degrees: asc.deg, minutes: asc.min),
                icon: "arrow.up.right.diamond.fill",
                tint: .mint
            ))
        }
        if let moonInsight = planetInsight(
            id: "moon",
            planetName: "Moon",
            title: "Moon",
            icon: "moon.stars.fill",
            tint: .cyan,
            detailBuilder: { "\(AngleFormatter.describe(position: $0)) - \($0.nakshatra) p\($0.pada)" }
        ) {
            list.append(moonInsight)
        }
        if let rahuInsight = planetInsight(
            id: "rahu",
            planetName: "Rahu",
            title: "Rahu",
            icon: "hare.fill",
            tint: .purple,
            detailBuilder: { "\(AngleFormatter.describe(position: $0)) node" }
        ) {
            list.append(rahuInsight)
        }
        if let ketuInsight = planetInsight(
            id: "ketu",
            planetName: "Ketu",
            title: "Ketu",
            icon: "arrow.down.circle.fill",
            tint: .gray,
            detailBuilder: { "\(AngleFormatter.describe(position: $0)) node" }
        ) {
            list.append(ketuInsight)
        }

        let standardPlanets: [(name: String, icon: String, tint: Color)] = [
            ("Sun", "sun.max.fill", .yellow),
            ("Mars", "flame.fill", .red),
            ("Mercury", "bolt.fill", .mint),
            ("Jupiter", "sparkles", .orange),
            ("Venus", "heart.fill", .pink),
            ("Saturn", "globe.americas.fill", .indigo)
        ]

        for descriptor in standardPlanets {
            if let insight = planetInsight(
                id: descriptor.name.lowercased(),
                planetName: descriptor.name,
                title: descriptor.name,
                icon: descriptor.icon,
                tint: descriptor.tint,
                detailBuilder: { AngleFormatter.describe(position: $0) }
            ) {
                list.append(insight)
            }
        }

        return list
    }

    private func planetInsight(
        id: String,
        planetName: String,
        title: String,
        icon: String,
        tint: Color,
        detailBuilder: (PlanetPosition) -> String
    ) -> CosmicInsight? {
        guard let planet = planetPositions.first(where: { $0.name == planetName }) else {
            return nil
        }
        return CosmicInsight(
            id: id,
            title: title,
            detail: detailBuilder(planet),
            icon: icon,
            tint: tint
        )
    }

    @ViewBuilder
    private func insightChip(_ insight: CosmicInsight) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(insight.tint.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: insight.icon)
                    .foregroundColor(insight.tint)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(insight.detail)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .padding(.trailing, 8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(CosmicTheme.midnight.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private struct DashboardStatCard: View {
        let descriptor: DashboardStatDescriptor

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: descriptor.icon)
                        .font(.headline)
                        .foregroundColor(CosmicTheme.accent)
                    Text(descriptor.title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                Text(descriptor.value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(descriptor.subtitle)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.secondaryText)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.clear
            )
            .cosmicGlass(cornerRadius: 24, tint: CosmicTheme.accent.opacity(0.7), highlightOpacity: 0.12)
        }
    }

    private func handleManualResync() {
        guard selectedCoordinate != nil else {
            toast = Toast(
                title: "Location required",
                subtitle: "Enter birth data in the Birth tab first",
                systemImage: "exclamationmark.triangle.fill"
            )
            return
        }
        recomputePlanets()
        toast = Toast(
            title: "Planets refreshed",
            subtitle: syncBadgeDetail,
            systemImage: "arrow.triangle.2.circlepath"
        )
    }

    private func recomputePlanets() {
        guard let coord = selectedCoordinate else {
            planetPositions = []
            calcError = nil
            lastSyncedAt = nil
            panchanga = nil
            return
        }
        planetPositions = calculator.compute(
            date: dateOfBirth,
            time: timeOfBirth,
            coordinate: coord,
            timeZone: selectedTimeZone
        )
        calcError = calculator.lastError
        if calcError == nil {
            lastSyncedAt = Date()
            
            // Calculate Panchanga
            // Combine date and time
            let calendar = Calendar.current
            let dateComps = calendar.dateComponents([.year, .month, .day], from: dateOfBirth)
            let timeComps = calendar.dateComponents([.hour, .minute, .second], from: timeOfBirth)
            
            var combinedComps = DateComponents()
            combinedComps.year = dateComps.year
            combinedComps.month = dateComps.month
            combinedComps.day = dateComps.day
            combinedComps.hour = timeComps.hour
            combinedComps.minute = timeComps.minute
            combinedComps.second = timeComps.second
            
            if let dateTime = calendar.date(from: combinedComps) {
                panchanga = PanchangaCalcIOS.compute(
                    planetPositions: planetPositions,
                    dateTime: dateTime,
                    timeZone: selectedTimeZone ?? .current
                )
            }
        } else {
            lastSyncedAt = nil
            panchanga = nil
        }
        // One-time Swiss OK toast
        let shownKey = "swissToastShown"
        if calcError == nil, calculator.epheFilesCount > 0, UserDefaults.standard.bool(forKey: shownKey) == false {
            UserDefaults.standard.set(true, forKey: shownKey)
            toast = Toast(title: "Swiss data ready", subtitle: "\(calculator.epheFilesCount) files in bundle", systemImage: "checkmark.seal.fill")
        }
    }

    private func recomputePartnerPlanets() {
        guard let coord = partnerSelectedCoordinate else {
            partnerPlanetPositions = []
            partnerCalcError = nil
            partnerLastSyncedAt = nil
            return
        }
        partnerPlanetPositions = partnerCalculator.compute(
            date: partnerDateOfBirth,
            time: partnerTimeOfBirth,
            coordinate: coord,
            timeZone: partnerSelectedTimeZone
        )
        partnerCalcError = partnerCalculator.lastError
        partnerLastSyncedAt = partnerCalcError == nil ? Date() : nil
    }
}

#Preview {
    ContentView()
}
