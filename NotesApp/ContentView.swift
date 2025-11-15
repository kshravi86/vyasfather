import SwiftUI
import MapKit
#if canImport(UIKit)
import UIKit
#endif

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
    @State private var submitted: Bool = true
    @State private var planetPositions: [PlanetPosition] = []
    private let calculator = PlanetaryCalculator()
    @State private var calcError: String? = nil
    @State private var toast: Toast? = nil
    @State private var lastSyncedAt: Date? = nil

    @State private var selectedTab: Int = 0
    @State private var showDiagnostics = false
    private let tabsMeta: [TabMetadata] = [
        TabMetadata(id: 0, title: "Birth", icon: "person.crop.circle", accent: .mint),
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
        TabMetadata(id: 11, title: "Pushkara", icon: "leaf.circle", accent: .green)
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
                cosmicDashboard

                TabView(selection: $selectedTab) {
                    BirthInfoView(
                        dateOfBirth: $dateOfBirth,
                        timeOfBirth: $timeOfBirth,
                        searchManager: searchManager,
                        selectedTitle: $selectedTitle,
                        selectedCoordinate: $selectedCoordinate,
                        selectedState: $selectedState,
                        selectedCountry: $selectedCountry,
                        submitted: $submitted,
                        planetPositions: $planetPositions,
                        calculator: calculator,
                        calcError: $calcError,
                        toast: $toast
                    )
                    .tag(0)

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
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .padding(.top, 12)

                MainTabView(selectedTab: $selectedTab, tabsMeta: tabsMeta)
                    .padding(.top, 12)
            }
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
        .sheet(isPresented: $showDiagnostics) {
            DiagnosticsView(
                ephePath: calculator.lastEphePath ?? "Swiss path unavailable",
                fileCount: calculator.epheFilesCount,
                samples: calculator.epheSamples,
                logs: calculator.logs
            )
            .preferredColorScheme(.dark)
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
        default: return nil
        }
    }

    private var cosmicTopBar: some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(CosmicTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vedic Light")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Sidereal intelligence on demand")
                        .font(.footnote)
                        .foregroundColor(CosmicTheme.secondaryText)
                }
            }
            Spacer()
            HStack(spacing: 8) {
                TagBadge(text: activeTabMetadata.title.uppercased(), color: activeTabMetadata.accent)
                if ScreenshotMode.isOn {
                    TagBadge(text: "SNAPSHOT", color: .pink)
                }
                TagBadge(text: statusBadge.text, color: statusBadge.color)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private var cosmicDashboard: some View {
        VStack(spacing: 20) {
            heroHeader
            actionStrip
            statsGrid
            insightsSection
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    LinearGradient(
                        colors: [
                            CosmicTheme.accent.opacity(0.25),
                            Color.purple.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blur(radius: 60)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 25)
        .padding(.horizontal, 16)
        .padding(.top, 32)
        .padding(.bottom, 12)
    }

    private var actionStrip: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                actionButtons
            }
            VStack(spacing: 12) {
                actionButtons
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        quickActionButton(
            icon: "arrow.triangle.2.circlepath",
            title: "Re-sync planets",
            subtitle: syncBadgeDetail,
            tint: activeTabMetadata.accent
        ) {
            handleManualResync()
        }
        quickActionButton(
            icon: "waveform.path.ecg",
            title: "Diagnostics",
            subtitle: diagnosticsSubtitle,
            tint: .pink
        ) {
            showDiagnostics = true
        }
    }

    private func quickActionButton(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            action()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundColor(tint)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                    .lineLimit(2)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cosmicGlass(cornerRadius: 24, tint: tint, highlightOpacity: 0.35)
        }
        .buttonStyle(.plain)
    }

    private var activeTabMetadata: TabMetadata {
        tabsMeta.first(where: { $0.id == selectedTab }) ?? tabsMeta[0]
    }

    private var statusBadge: (text: String, color: Color) {
        if let calcError {
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

    private var recomputeInput: RecomputeInput {
        RecomputeInput(date: dateOfBirth, time: timeOfBirth, coordinate: activeCoordinate)
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Astro intelligence")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                    Text(heroLine)
                        .font(.callout)
                        .foregroundColor(CosmicTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                infoChip(icon: syncIconName, title: syncBadgeText, subtitle: syncBadgeDetail, tint: syncTint)
                    .frame(maxWidth: 180)
            }

            HStack(spacing: 12) {
                infoChip(
                    icon: "mappin.and.ellipse",
                    title: locationDescriptor,
                    subtitle: coordinateDescriptor,
                    tint: .mint
                )
                infoChip(
                    icon: "calendar.badge.clock",
                    title: Self.dateFormatter.string(from: dateOfBirth),
                    subtitle: Self.timeFormatter.string(from: timeOfBirth),
                    tint: .cyan
                )
            }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: statColumns, spacing: 16) {
            ForEach(statDescriptors) { descriptor in
                DashboardStatCard(descriptor: descriptor)
            }
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Live insights", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if !planetPositions.isEmpty {
                    Text("\(currentInsights.count) bodies tracked")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText)
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
                }
            }

            if let calcError {
                errorCallout(calcError)
            }
        }
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
        .cosmicGlass(cornerRadius: 20, tint: tint.opacity(0.8), highlightOpacity: 0.25)
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
        .cosmicGlass(cornerRadius: 22, tint: Color.white.opacity(0.3), highlightOpacity: 0.18)
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

    private var currentInsights: [CosmicInsight] {
        var list: [CosmicInsight] = []
        if let asc = calculator.ascendant {
            list.append(CosmicInsight(
                id: "ascendant",
                title: "Ascendant",
                detail: "\(asc.sign) \(asc.deg)?\(asc.min)'",
                icon: "arrow.up.right.diamond.fill",
                tint: .mint
            ))
        }
        if let moon = planetPositions.first(where: { $0.name == "Moon" }) {
            list.append(CosmicInsight(
                id: "moon",
                title: "Moon",
                detail: "\(moon.sign) ?? \(moon.nakshatra) p\(moon.pada)",
                icon: "moon.stars.fill",
                tint: .cyan
            ))
        }
        if let sun = planetPositions.first(where: { $0.name == "Sun" }) {
            list.append(CosmicInsight(
                id: "sun",
                title: "Sun",
                detail: "\(sun.sign) \(sun.deg)?\(sun.min)'",
                icon: "sun.max.fill",
                tint: .yellow
            ))
        }
        if let rahu = planetPositions.first(where: { $0.name == "Rahu" }) {
            list.append(CosmicInsight(
                id: "rahu",
                title: "Rahu",
                detail: "\(rahu.sign) node",
                icon: "hare.fill",
                tint: .purple
            ))
        }
        if let ketu = planetPositions.first(where: { $0.name == "Ketu" }) {
            list.append(CosmicInsight(
                id: "ketu",
                title: "Ketu",
                detail: "\(ketu.sign) node",
                icon: "arrow.down.circle.fill",
                tint: .gray
            ))
        }
        if let mars = planetPositions.first(where: { $0.name == "Mars" }) {
            list.append(CosmicInsight(
                id: "mars",
                title: "Mars",
                detail: "\(mars.sign) \(mars.deg)?\(mars.min)'",
                icon: "flame.fill",
                tint: .red
            ))
        }
        if let mercury = planetPositions.first(where: { $0.name == "Mercury" }) {
            list.append(CosmicInsight(
                id: "mercury",
                title: "Mercury",
                detail: "\(mercury.sign) \(mercury.deg)?\(mercury.min)'",
                icon: "bolt.fill",
                tint: .mint
            ))
        }
        if let jupiter = planetPositions.first(where: { $0.name == "Jupiter" }) {
            list.append(CosmicInsight(
                id: "jupiter",
                title: "Jupiter",
                detail: "\(jupiter.sign) \(jupiter.deg)?\(jupiter.min)'",
                icon: "sparkles",
                tint: .orange
            ))
        }
        if let venus = planetPositions.first(where: { $0.name == "Venus" }) {
            list.append(CosmicInsight(
                id: "venus",
                title: "Venus",
                detail: "\(venus.sign) \(venus.deg)?\(venus.min)'",
                icon: "heart.fill",
                tint: .pink
            ))
        }
        if let saturn = planetPositions.first(where: { $0.name == "Saturn" }) {
            list.append(CosmicInsight(
                id: "saturn",
                title: "Saturn",
                detail: "\(saturn.sign) \(saturn.deg)?\(saturn.min)'",
                icon: "globe.americas.fill",
                tint: .indigo
            ))
        }
        return list
    }

    @ViewBuilder
    private func insightChip(_ insight: CosmicInsight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: insight.icon)
                    .foregroundColor(insight.tint)
                    .font(.headline)
                Text(insight.title)
                    .font(.headline)
            }
            Text(insight.detail)
                .font(.caption)
                .foregroundColor(CosmicTheme.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .cosmicGlass(cornerRadius: 22, tint: insight.tint.opacity(0.9), highlightOpacity: 0.4)
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
            .cosmicGlass(cornerRadius: 24, tint: CosmicTheme.accent.opacity(0.7), highlightOpacity: 0.25)
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
            return
        }
        planetPositions = calculator.compute(date: dateOfBirth, time: timeOfBirth, coordinate: coord)
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
}

#Preview {
    ContentView()
}
