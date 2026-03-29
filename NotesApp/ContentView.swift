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
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(greetingText.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundColor(CosmicTheme.secondaryText.opacity(0.9))

                Text(selectedTab == 0 ? "Cosmic Dashboard" : activeTabMetadata.title)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundColor(CosmicTheme.starlight)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                ViewThatFits {
                    HStack(spacing: 8) {
                        dashboardStatusPill(
                            text: syncBadgeText,
                            icon: syncIconName,
                            tint: syncTint
                        )

                        if !selectedTitle.isEmpty {
                            dashboardStatusPill(
                                text: selectedTitle,
                                icon: "mappin.and.ellipse",
                                tint: activeTabMetadata.accent
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        dashboardStatusPill(
                            text: syncBadgeText,
                            icon: syncIconName,
                            tint: syncTint
                        )

                        if !selectedTitle.isEmpty {
                            dashboardStatusPill(
                                text: selectedTitle,
                                icon: "mappin.and.ellipse",
                                tint: activeTabMetadata.accent
                            )
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            Button {
                handleManualResync()
            } label: {
                ZStack {
                    Circle()
                        .fill(CosmicTheme.auroraGradient.opacity(0.16))
                        .frame(width: 52, height: 52)

                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 52, height: 52)

                    Circle()
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        .frame(width: 52, height: 52)

                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white.opacity(0.92))
                }
                .shadow(color: CosmicTheme.accent.opacity(0.18), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var cosmicDashboard: some View {
        VStack(alignment: .leading, spacing: 20) {
            dashboardHero

            LazyVGrid(columns: statColumns, spacing: 14) {
                ForEach(statDescriptors) { descriptor in
                    DashboardStatCard(descriptor: descriptor)
                }
            }

            if let calcError {
                errorCallout(calcError)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Planetary Highlights")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)

                    Spacer()

                    if !currentInsights.isEmpty {
                        TagBadge(text: "\(currentInsights.count) live", color: CosmicTheme.accentSoft)
                    }
                }

                if currentInsights.isEmpty {
                    insightPlaceholder
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(currentInsights) { insight in
                                insightChip(insight)
                            }
                        }
                        .padding(.trailing, 4)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    private var actionStrip: some View {
        EmptyView() // Deprecated
    }

    private var activeTabMetadata: TabMetadata {
        tabsMeta.first(where: { $0.id == selectedTab }) ?? tabsMeta[0]
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

    private var dashboardHero: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("BIRTH BLUEPRINT")
                        .font(.caption.weight(.bold))
                        .tracking(2.2)
                        .foregroundColor(CosmicTheme.secondaryText)

                    Text(selectedTitle.isEmpty ? "Set your birth details" : selectedTitle)
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    Text(heroLine)
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.secondaryText)
                        .lineSpacing(3)
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(activeTabMetadata.accent.opacity(0.16))
                        .frame(width: 58, height: 58)

                    Image(systemName: activeTabMetadata.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(activeTabMetadata.accent)
                }
            }

            ViewThatFits {
                HStack(spacing: 10) {
                    dashboardStatusPill(
                        text: locationDescriptor,
                        icon: "mappin.and.ellipse",
                        tint: activeTabMetadata.accent
                    )

                    dashboardStatusPill(
                        text: coordinateDescriptor,
                        icon: "location.north.line",
                        tint: CosmicTheme.accentSoft
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    dashboardStatusPill(
                        text: locationDescriptor,
                        icon: "mappin.and.ellipse",
                        tint: activeTabMetadata.accent
                    )

                    dashboardStatusPill(
                        text: coordinateDescriptor,
                        icon: "location.north.line",
                        tint: CosmicTheme.accentSoft
                    )
                }
            }

            ViewThatFits {
                HStack(spacing: 12) {
                    infoChip(
                        icon: "calendar",
                        title: Self.dateFormatter.string(from: dateOfBirth),
                        subtitle: "Birth date",
                        tint: CosmicTheme.accent
                    )

                    infoChip(
                        icon: "clock",
                        title: Self.timeFormatter.string(from: timeOfBirth),
                        subtitle: "Birth time",
                        tint: CosmicTheme.accentSoft
                    )

                    infoChip(
                        icon: "sparkles",
                        title: syncBadgeText,
                        subtitle: diagnosticsSubtitle,
                        tint: syncTint
                    )
                }

                VStack(spacing: 12) {
                    infoChip(
                        icon: "calendar",
                        title: Self.dateFormatter.string(from: dateOfBirth),
                        subtitle: "Birth date",
                        tint: CosmicTheme.accent
                    )

                    infoChip(
                        icon: "clock",
                        title: Self.timeFormatter.string(from: timeOfBirth),
                        subtitle: "Birth time",
                        tint: CosmicTheme.accentSoft
                    )

                    infoChip(
                        icon: "sparkles",
                        title: syncBadgeText,
                        subtitle: diagnosticsSubtitle,
                        tint: syncTint
                    )
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color.white.opacity(0.06))

                Circle()
                    .fill(CosmicTheme.accent.opacity(0.14))
                    .frame(width: 190, height: 190)
                    .blur(radius: 12)
                    .offset(x: 70, y: -90)

                Circle()
                    .fill(CosmicTheme.accentSoft.opacity(0.12))
                    .frame(width: 150, height: 150)
                    .blur(radius: 18)
                    .offset(x: -40, y: 80)

                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(CosmicTheme.heroGradient.opacity(0.30))
            }
        )
        .cosmicGlass(cornerRadius: 34, tint: activeTabMetadata.accent, highlightOpacity: 0.18)
    }

    private func infoChip(icon: String, title: String, subtitle: String?, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.16))
                        .frame(width: 28, height: 28)

                    Image(systemName: icon)
                        .font(.footnote.weight(.bold))
                        .foregroundColor(tint)
                }

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
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cosmicGlass(cornerRadius: 20, tint: tint.opacity(0.8), highlightOpacity: 0.16)
    }

    private var insightPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No planetary data yet")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            Text("Enter birth details in the Birth tab to unlock personalised yogas, dashas and auspicious timings.")
                .font(.caption)
                .foregroundColor(CosmicTheme.secondaryText)
                .lineSpacing(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cosmicGlass(cornerRadius: 22, tint: CosmicTheme.accentSoft.opacity(0.5), highlightOpacity: 0.1)
    }

    private func errorCallout(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 4) {
                Text("Calculation issue")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.86))

                Text(message)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineSpacing(2)
            }
        }
        .padding(16)
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
                    .fill(insight.tint.opacity(0.18))
                    .frame(width: 42, height: 42)

                Image(systemName: insight.icon)
                    .foregroundColor(insight.tint)
                    .font(.system(size: 17, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)

                Text(insight.detail)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(width: 220, alignment: .leading)
        .cosmicGlass(cornerRadius: 24, tint: insight.tint, highlightOpacity: 0.14)
    }

    private struct DashboardStatCard: View {
        let descriptor: DashboardStatDescriptor

        var body: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(descriptor.title.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(1.2)
                            .foregroundColor(CosmicTheme.secondaryText)

                        Text(descriptor.value)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 10)

                    ZStack {
                        Circle()
                            .fill(CosmicTheme.accent.opacity(0.16))
                            .frame(width: 32, height: 32)

                        Image(systemName: descriptor.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(CosmicTheme.accent)
                    }
                }

                Text(descriptor.subtitle)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                    .lineLimit(2)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cosmicGlass(cornerRadius: 24, tint: CosmicTheme.accent.opacity(0.7), highlightOpacity: 0.12)
        }
    }

    private func dashboardStatusPill(text: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundColor(tint)

            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(tint.opacity(0.30), lineWidth: 1)
                )
        )
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
        } else {
            lastSyncedAt = nil
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
