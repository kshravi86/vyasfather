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
    @Environment(\.colorScheme) private var colorScheme

    // Formatters
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()
    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df
    }()

    @State private var selectedTab: Int = 0
    private let tabCount: Int = 12
    private struct TabMeta: Identifiable {
        let id: Int
        let title: String
        let icon: String
    }
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
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        if let err = calcError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.white)
                                Text(err)
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        VStack(alignment: .leading, spacing: 15) {
                            Text("Birth Details")
                                .font(.title2).bold()
                                .foregroundColor(CosmicTheme.text)
                            DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                            DatePicker("Time of Birth", selection: $timeOfBirth, displayedComponents: .hourAndMinute)
                        }
                        .cardBackground()

                        VStack(alignment: .leading, spacing: 15) {
                            Text("Place of Birth")
                                .font(.title2).bold()
                                .foregroundColor(CosmicTheme.text)

                            HStack {
                                Image(systemName: "magnifyingglass").foregroundColor(CosmicTheme.secondaryText)
                                TextField("Enter place name", text: $searchManager.searchQuery)
                                    .autocorrectionDisabled(true)
                                    .textInputAutocapitalization(.words)
                            }

                            if !searchManager.searchResults.isEmpty {
                                List(Array(searchManager.searchResults.enumerated()), id: \.0) { _, result in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.title).font(.body)
                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle).font(.caption).foregroundColor(CosmicTheme.secondaryText)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        searchManager.getPlacemark(for: result) { placemark, _ in
                                            if let pm = placemark {
                                                self.selectedTitle = result.title
                                                self.selectedCoordinate = pm.coordinate
                                                self.selectedState = pm.administrativeArea ?? ""
                                                self.selectedCountry = pm.country ?? ""
                                                self.submitted = false
                                            }
                                        }
                                    }
                                }
                                .frame(minHeight: 120, maxHeight: 240)
                                .listStyle(.plain)
                            }

                            if let c = selectedCoordinate {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Selected: \(selectedTitle)").font(.headline)
                                    Text(String(format: "Lat: %.6f, Lon: %.6f", c.latitude, c.longitude))
                                        .font(.subheadline)
                                        .foregroundColor(CosmicTheme.secondaryText)
                                    if !selectedState.isEmpty || !selectedCountry.isEmpty {
                                        Text([selectedState, selectedCountry].filter { !$0.isEmpty }.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(CosmicTheme.secondaryText)
                                    }
                                }
                            }
                        }
                        .cardBackground()

                        Button(action: submit) {
                            Text("Create Chart")
                                .font(.headline)
                                .foregroundColor(CosmicTheme.background)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(CosmicTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        }
                        .disabled(selectedCoordinate == nil)

                        if submitted {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Planetary Positions (Lahiri)")
                                    .font(.title2).bold()
                                    .foregroundColor(CosmicTheme.text)

                                if planetPositions.isEmpty {
                                    ProgressView()
                                } else {
                                    ZodiacView(planetPositions: planetPositions)
                                        .padding(.vertical)

                                    ForEach(planetPositions) { pos in
                                        HStack {
                                            PlanetChip(name: pos.name)
                                            Spacer()
                                            Text("\(pos.sign) \(pos.deg)°\(pos.min)'  ·  \(pos.nakshatra) p\(pos.pada)" + (pos.retrograde ? "  ℞" : ""))
                                                .foregroundColor(CosmicTheme.secondaryText)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                            .cardBackground()
                        }
                    }
                    .padding()
                }
                .navigationTitle("Birth Info")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showDiagnostics = true
                        } label: {
                            Image(systemName: "wrench.and.screwdriver")
                        }
                        .accessibilityLabel("Diagnostics")
                    }
                }
                .background(CosmicTheme.gradient(for: colorScheme))
                .foregroundColor(CosmicTheme.text)
            }
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

            // Bottom sliding tab strip (visible tabs) + tap to switch
            Divider().opacity(0.2)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(tabsMeta) { meta in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = meta.id
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: meta.icon)
                                    .font(.subheadline)
                                Text(meta.title)
                                    .font(.caption)
                                    .fontWeight(selectedTab == meta.id ? .bold : .medium)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .frame(minWidth: 80)
                            .background(selectedTab == meta.id ? CosmicTheme.accent.opacity(0.2) : Color.clear)
                            .foregroundColor(selectedTab == meta.id ? CosmicTheme.accent : CosmicTheme.text)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(CosmicTheme.background.opacity(0.9))
            }
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

    private func submit() {
        submitted = true
        recomputePlanets()
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

    private func labeledHeader(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(CosmicTheme.accent)
            Text(title).font(.headline)
        }
    }
}
#Preview {
    ContentView()
}
