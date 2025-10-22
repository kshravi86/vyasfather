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
    private let tabsMeta: [(Int, String, String)] = [
        (0, "Birth", "person.crop.circle"),
        (1, "Dasha", "moon.stars.fill"),
        (2, "Yogi", "sun.max.trianglebadge.exclamationmark"),
        (3, "Uttama", "seal.fill"),
        (4, "Jaimini", "text.badge.star"),
        (5, "Panchanga", "calendar"),
        (6, "Ishta", "flame.fill"),
        (7, "D9", "square.grid.3x3"),
        (8, "D7", "square.grid.3x2"),
        (9, "Lagnas", "clock.badge.checkmark"),
        (10, "64/22", "circle.hexagongrid"),
        (11, "Pushkara", "leaf.circle")
    ]

    var body: some View {
        VStack(spacing: 8) {
            // Top sliding tab strip (visible tabs) + tap to switch
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tabsMeta, id: \.0) { meta in
                        let (id, title, icon) = meta
                        Button(action: { selectedTab = id }) {
                            HStack(spacing: 6) {
                                Image(systemName: icon).font(.caption)
                                Text(title)
                                    .font(.caption)
                                    .fontWeight(selectedTab == id ? .bold : .regular)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(selectedTab == id ? Color("AccentColor").opacity(0.15) : Color.clear)
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 12)
            }

            TabView(selection: $selectedTab) {
            NavigationView {
                Form {
                if let err = calcError {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                            Text(err)
                                .foregroundColor(.white)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .listRowBackground(Color.red.opacity(0.9))
                }
                

                Section(header: labeledHeader(title: "Birth Details", systemImage: "calendar").textCase(nil)) {
                    VStack(spacing: 10) {
                        DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        Divider()
                        DatePicker("Time of Birth", selection: $timeOfBirth, displayedComponents: .hourAndMinute)
                    }
                    .cardBackground()
                    .listRowSeparator(.hidden)
                }

                Section(header: labeledHeader(title: "Place of Birth", systemImage: "mappin.and.ellipse").textCase(nil)) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                            TextField("Enter place name", text: $searchManager.searchQuery)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.words)
                        }

                        if !searchManager.searchResults.isEmpty {
                            List(Array(searchManager.searchResults.enumerated()), id: \.0) { _, result in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.title).font(.body)
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle).font(.caption).foregroundColor(.secondary)
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
                                Text("Selected: \(selectedTitle)").font(.subheadline)
                                Text(String(format: "Lat: %.6f, Lon: %.6f", c.latitude, c.longitude))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if !selectedState.isEmpty || !selectedCountry.isEmpty {
                                    Text([selectedState, selectedCountry].filter { !$0.isEmpty }.joined(separator: ", "))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Divider()
                                HStack {
                                    Text("Latitude")
                                    Spacer()
                                    Text(String(format: "%.6f", c.latitude)).foregroundColor(.secondary)
                                }
                                HStack {
                                    Text("Longitude")
                                    Spacer()
                                    Text(String(format: "%.6f", c.longitude)).foregroundColor(.secondary)
                                }
                            }
                            .cardBackground()
                        }
                    }
                }

                Section {
                    Button(action: submit) {
                        HStack {
                            Spacer()
                            Text("Create")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(selectedCoordinate == nil)
                }

                if submitted {
                    Section(header: Text("Submitted")) {
                        HStack {
                            Text("Date")
                            Spacer()
                            Text(dateFormatter.string(from: dateOfBirth)).foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Time")
                            Spacer()
                            Text(timeFormatter.string(from: timeOfBirth)).foregroundColor(.secondary)
                        }
                        if let c = selectedCoordinate {
                            HStack {
                                Text("Latitude")
                                Spacer()
                                Text(String(format: "%.6f", c.latitude)).foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Longitude")
                                Spacer()
                                Text(String(format: "%.6f", c.longitude)).foregroundColor(.secondary)
                            }
                        }
                    }
                }

                    Section(header: labeledHeader(title: "Planetary Positions (Lahiri)", systemImage: "sparkles").textCase(nil)) {
                        if planetPositions.isEmpty {
                            Text("Calculating...").foregroundColor(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                if let path = calculator.lastEphePath {
                                    Text("Swiss data: \(URL(fileURLWithPath: path).lastPathComponent) (\(calculator.epheFilesCount) files)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Swiss data path not found")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                ForEach(planetPositions) { pos in
                                    HStack {
                                        PlanetChip(name: pos.name)
                                        Spacer(minLength: 8)
                                        Text("\(pos.sign) \(pos.deg)°\(pos.min)'  ·  \(pos.nakshatra) p\(pos.pada)" + (pos.retrograde ? "  ℞" : ""))
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .cardBackground()
                        }
                    }

                    // (Hidden) Ascendant & Houses: calculations still run; not displayed per request.
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
                .scrollContentBackground(.hidden)
                .background(WaterTheme.gradient(for: colorScheme))
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
        }
        .tint(Color("AccentColor"))
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
                .foregroundColor(Color("AccentColor"))
            Text(title).font(.headline)
        }
    }
}
#Preview {
    ContentView()
}
