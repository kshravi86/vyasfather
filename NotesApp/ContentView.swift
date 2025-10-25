import SwiftUI
import MapKit

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

    @State private var selectedTab: Int = 0
    private let tabsMeta: [TabMetadata] = [
        TabMetadata(id: 0, title: "Birth", icon: "person.crop.circle"),
        TabMetadata(id: 1, title: "Dasha", icon: "moon.stars.fill"),
        TabMetadata(id: 2, title: "Yogi", icon: "sun.max.trianglebadge.exclamationmark"),
        TabMetadata(id: 3, title: "Uttama", icon: "seal.fill"),
        TabMetadata(id: 4, title: "Jaimini", icon: "text.badge.star"),
        TabMetadata(id: 5, title: "Panchanga", icon: "calendar"),
        TabMetadata(id: 6, title: "Ishta", icon: "flame.fill"),
        TabMetadata(id: 7, title: "D9", icon: "square.grid.3x3"),
        TabMetadata(id: 8, title: "D7", icon: "square.grid.3x2"),
        TabMetadata(id: 9, title: "Lagnas", icon: "clock.badge.checkmark"),
        TabMetadata(id: 10, title: "64/22", icon: "circle.hexagongrid"),
        TabMetadata(id: 11, title: "Pushkara", icon: "leaf.circle")
    ]

    private struct CosmicInsight: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let icon: String
        let tint: Color
    }

    var body: some View {
        ZStack {
            CosmicBackgroundView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
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
        .onChange(of: dateOfBirth) { _ in recomputePlanets() }
        .onChange(of: timeOfBirth) { _ in recomputePlanets() }
        .onChange(of: selectedCoordinate?.latitude) { _ in recomputePlanets() }
        .onChange(of: selectedCoordinate?.longitude) { _ in recomputePlanets() }
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

    private var cosmicDashboard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Astro intelligence")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
            Text(heroLine)
                .font(.callout)
                .foregroundColor(CosmicTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(currentInsights) { insight in
                        insightChip(insight)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 48)
        .padding(.bottom, 16)
    }

    private var heroLine: String {
        if planetPositions.isEmpty {
            return "Provide birth inputs to unlock personalised dashas, yogas and auspicious timings."
        }
        if let moon = planetPositions.first(where: { $0.name == "Moon" }) {
            return "Moon resides in \(moon.sign) • \(moon.nakshatra) pada \(moon.pada) guiding the mind's rhythm today."
        }
        if let asc = calculator.ascendant {
            return "Ascendant anchored in \(asc.sign) at \(asc.deg)°\(asc.min)' is ready for exploration."
        }
        return "Your cosmic dashboard is hydrated with planetary intelligence."
    }

    private var currentInsights: [CosmicInsight] {
        var list: [CosmicInsight] = []
        if let asc = calculator.ascendant {
            list.append(CosmicInsight(
                title: "Ascendant",
                detail: "\(asc.sign) \(asc.deg)°\(asc.min)'",
                icon: "arrow.up.right.diamond.fill",
                tint: .mint
            ))
        }
        if let moon = planetPositions.first(where: { $0.name == "Moon" }) {
            list.append(CosmicInsight(
                title: "Moon",
                detail: "\(moon.sign) • \(moon.nakshatra) p\(moon.pada)",
                icon: "moon.stars.fill",
                tint: .cyan
            ))
        }
        if let sun = planetPositions.first(where: { $0.name == "Sun" }) {
            list.append(CosmicInsight(
                title: "Sun",
                detail: "\(sun.sign) \(sun.deg)°\(sun.min)'",
                icon: "sun.max.fill",
                tint: .yellow
            ))
        }
        if let rahu = planetPositions.first(where: { $0.name == "Rahu" }) {
            list.append(CosmicInsight(
                title: "Rahu",
                detail: "\(rahu.sign) node",
                icon: "hare.fill",
                tint: .purple
            ))
        }
        if let ketu = planetPositions.first(where: { $0.name == "Ketu" }) {
            list.append(CosmicInsight(
                title: "Ketu",
                detail: "\(ketu.sign) node",
                icon: "arrow.down.circle.fill",
                tint: .gray
            ))
        }
        if let mars = planetPositions.first(where: { $0.name == "Mars" }) {
            list.append(CosmicInsight(
                title: "Mars",
                detail: "\(mars.sign) \(mars.deg)°\(mars.min)'",
                icon: "flame.fill",
                tint: .red
            ))
        }
        if let mercury = planetPositions.first(where: { $0.name == "Mercury" }) {
            list.append(CosmicInsight(
                title: "Mercury",
                detail: "\(mercury.sign) \(mercury.deg)°\(mercury.min)'",
                icon: "bolt.fill",
                tint: .mint
            ))
        }
        if let jupiter = planetPositions.first(where: { $0.name == "Jupiter" }) {
            list.append(CosmicInsight(
                title: "Jupiter",
                detail: "\(jupiter.sign) \(jupiter.deg)°\(jupiter.min)'",
                icon: "sparkles",
                tint: .orange
            ))
        }
        if let venus = planetPositions.first(where: { $0.name == "Venus" }) {
            list.append(CosmicInsight(
                title: "Venus",
                detail: "\(venus.sign) \(venus.deg)°\(venus.min)'",
                icon: "heart.fill",
                tint: .pink
            ))
        }
        if let saturn = planetPositions.first(where: { $0.name == "Saturn" }) {
            list.append(CosmicInsight(
                title: "Saturn",
                detail: "\(saturn.sign) \(saturn.deg)°\(saturn.min)'",
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
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func recomputePlanets() {
        guard let coord = selectedCoordinate else { planetPositions = []; return }
        planetPositions = calculator.compute(date: dateOfBirth, time: timeOfBirth, coordinate: coord)
        calcError = calculator.lastError
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
