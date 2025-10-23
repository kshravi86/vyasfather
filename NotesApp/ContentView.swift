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
    @State private var showDiagnostics: Bool = false

    @State private var selectedTab: Int = 0
    private let tabsMeta: [TabMeta] = [
        TabMeta(id: 0, title: "Birth", icon: "person.crop.circle"),
        TabMeta(id: 1, title: "Dasha", icon: "moon.stars.fill"),
        TabMeta(id: 2, title: "Yogi", icon: "sun.max.trianglebadge.exclamationmark"),
        TabMeta(id: 3, title: "Uttama", icon: "seal.fill"),
        TabMeta(id: 4, title: "Jaimini", icon: "text.badge.star"),
        TabMeta(id: 5, title: "Panchanga", icon: "calendar"),
        TabMeta(id: 6, title: "Ishta", icon: "flame.fill"),
        TabMeta(id: 7, title: "D9", icon: "square.grid.3x3"),
        TabMeta(id: 8, title: "D7", icon: "square.grid.3x2"),
        TabMeta(id: 9, title: "Lagnas", icon: "clock.badge.checkmark"),
        TabMeta(id: 10, title: "64/22", icon: "circle.hexagongrid"),
        TabMeta(id: 11, title: "Pushkara", icon: "leaf.circle")
    ]

    var body: some View {
        VStack(spacing: 0) {
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
                    toast: $toast,
                    showDiagnostics: $showDiagnostics
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

            MainTabView(selectedTab: $selectedTab, tabsMeta: tabsMeta)
        }
        .tint(CosmicTheme.accent)
        .onAppear { recomputePlanets() }
        .onChange(of: dateOfBirth) { _ in recomputePlanets() }
        .onChange(of: timeOfBirth) { _ in recomputePlanets() }
        .onChange(of: selectedCoordinate?.latitude) { _ in recomputePlanets() }
        .onChange(of: selectedCoordinate?.longitude) { _ in recomputePlanets() }
        .toast($toast)
        .sheet(isPresented: $showDiagnostics) {
            DiagnosticsView(
                ephePath: calculator.lastEphePath ?? "(not found)",
                fileCount: calculator.epheFilesCount,
                samples: calculator.epheSamples,
                logs: calculator.logs
            )
        }
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
