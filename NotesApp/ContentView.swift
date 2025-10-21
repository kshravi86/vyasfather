import SwiftUI
import MapKit

struct ContentView: View {
    // Inputs
    @State private var dateOfBirth: Date = Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1)) ?? Date()
    @State private var timeOfBirth: Date = {
        var comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        comps.second = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @State private var placeQuery: String = ""

    // Autocomplete
    @State private var completer = MKLocalSearchCompleter()
    @State private var suggestions: [MKLocalSearchCompletion] = []
    @State private var isSearching: Bool = false

    // Selection result
    @State private var selectedPlacemark: MKPlacemark? = nil
    @State private var submitted: Bool = false

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
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Enter city or place", text: $placeQuery)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.words)
                            .onChange(of: placeQuery) { newValue in
                                updateSuggestions(for: newValue)
                            }
                    }

                    if isSearching {
                        ProgressView().progressViewStyle(.circular)
                    }

                    if !suggestions.isEmpty {
                        List(suggestions, id: \.title) { item in
                            Button(action: { selectSuggestion(item) }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title).font(.body)
                                    if !item.subtitle.isEmpty {
                                        Text(item.subtitle).font(.caption).foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .frame(minHeight: 120, maxHeight: 240)
                    }

                    if let pm = selectedPlacemark {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Selected: \(pm.locality ?? pm.name ?? "")")
                                .font(.subheadline)
                            if let c = pm.location?.coordinate {
                                Text(String(format: "Lat: %.6f, Lon: %.6f", c.latitude, c.longitude))
                                    .font(.caption)
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
                    .disabled(placeQuery.isEmpty || selectedPlacemark == nil)
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
                        if let c = selectedPlacemark?.location?.coordinate {
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
            }
            .navigationTitle("Birth Info")
        }
        .onAppear {
            configureCompleter()
        }
        .tint(Color("AccentColor"))
    }

    private func configureCompleter() {
        completer.resultTypes = [.address, .pointOfInterest]
        completer.region = MKCoordinateRegion(.world)
        completer.delegate = CompleterDelegate { completions in
            self.suggestions = completions
            self.isSearching = false
        }
    }

    private func updateSuggestions(for fragment: String) {
        guard !fragment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            suggestions = []
            return
        }
        isSearching = true
        completer.queryFragment = fragment
    }

    private func selectSuggestion(_ item: MKLocalSearchCompletion) {
        placeQuery = item.title + (item.subtitle.isEmpty ? "" : ", \(item.subtitle)")
        suggestions = []
        resolveCompletion(item) { placemark in
            self.selectedPlacemark = placemark
        }
    }

    private func resolveCompletion(_ item: MKLocalSearchCompletion, completion: @escaping (MKPlacemark?) -> Void) {
        let request = MKLocalSearch.Request(completion: item)
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard error == nil, let mapItem = response?.mapItems.first else {
                completion(nil)
                return
            }
            completion(mapItem.placemark)
        }
    }

    private func submit() {
        submitted = true
    }
}

private final class CompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    private let onUpdate: ([MKLocalSearchCompletion]) -> Void
    init(onUpdate: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.onUpdate = onUpdate
    }
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate(completer.results)
    }
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onUpdate([])
    }
}

#Preview {
    ContentView()
}
