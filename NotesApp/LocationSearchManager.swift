import Foundation
import MapKit
import CoreLocation

final class LocationSearchManager: NSObject, ObservableObject {
    private let searchCompleter = MKLocalSearchCompleter()
    private let indiaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
        span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
    )
    private let worldRegion = MKCoordinateRegion(.world)
    private var usingIndiaRegion = true
    private var debounceWork: DispatchWorkItem?

    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var searchQuery: String = "" {
        didSet {
            let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            debounceWork?.cancel()
            guard trimmed.count >= 3 else {
                self.searchResults = []
                return
            }
            let work = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.usingIndiaRegion = true
                self.searchCompleter.region = self.indiaRegion
                self.searchCompleter.queryFragment = trimmed
            }
            debounceWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
        }
    }

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.region = indiaRegion
        searchCompleter.resultTypes = .address
    }

    // New: resolve full placemark (for state/country display)
    func getPlacemark(for completion: MKLocalSearchCompletion, completionHandler: @escaping (MKPlacemark?, String?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                completionHandler(nil, error.localizedDescription)
                return
            }
            if let mapItem = response?.mapItems.first {
                completionHandler(mapItem.placemark, nil)
            } else {
                completionHandler(nil, "No location found")
            }
        }
    }

    // Backward-compat: coordinate-only helper
    func getCoordinates(for completion: MKLocalSearchCompletion, completionHandler: @escaping (CLLocationCoordinate2D?, String?) -> Void) {
        getPlacemark(for: completion) { placemark, error in
            if let pm = placemark { completionHandler(pm.coordinate, nil) }
            else { completionHandler(nil, error) }
        }
    }
}

extension LocationSearchManager: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // If no results with India region, widen to world and try once
        if searchResults.isEmpty && usingIndiaRegion && !searchQuery.isEmpty {
            usingIndiaRegion = false
            searchCompleter.region = worldRegion
            searchCompleter.queryFragment = searchQuery
            return
        }
        self.searchResults = completer.results
    }
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        self.searchResults = []
    }
}
