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

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Birth Details")) {
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    DatePicker("Time of Birth", selection: $timeOfBirth, displayedComponents: .hourAndMinute)
                }

                Section(header: Text("Place of Birth")) {
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

                Section(header: Text("Planetary Positions (Lahiri)")) {
                    if planetPositions.isEmpty {
                        Text("Calculating...").foregroundColor(.secondary)
                    } else {
                        ForEach(planetPositions) { pos in
                            HStack {
                                Text(pos.name)
                                Spacer()
                                Text("\(pos.sign) \(pos.deg)°\(pos.min)'  ·  \(pos.nakshatra) p\(pos.pada)")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Birth Info")
        }
        .tint(Color("AccentColor"))
        .onAppear { recomputePlanets() }
        .onChange(of: dateOfBirth) { _ in recomputePlanets() }
        .onChange(of: timeOfBirth) { _ in recomputePlanets() }
        .onChange(of: selectedCoordinate?.latitude) { _ in recomputePlanets() }
        .onChange(of: selectedCoordinate?.longitude) { _ in recomputePlanets() }
    }

    private func submit() {
        submitted = true
        recomputePlanets()
    }

    private func recomputePlanets() {
        guard let coord = selectedCoordinate else { planetPositions = []; return }
        planetPositions = calculator.compute(date: dateOfBirth, time: timeOfBirth, coordinate: coord)
    }
}
#Preview {
    ContentView()
}
