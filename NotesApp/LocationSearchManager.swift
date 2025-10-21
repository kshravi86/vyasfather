import Foundation
import MapKit
import CoreLocation

final class LocationSearchManager: NSObject, ObservableObject {
    private let searchCompleter = MKLocalSearchCompleter()

    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var searchQuery: String = "" {
        didSet {
            let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count >= 3 {
                searchCompleter.queryFragment = trimmed
            } else {
                searchResults = []
            }
        }
    }

    override init() {
        super.init()
        searchCompleter.delegate = self
        let indiaRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
        )
        searchCompleter.region = indiaRegion
        searchCompleter.resultTypes = .address
    }

    func getCoordinates(for completion: MKLocalSearchCompletion, completionHandler: @escaping (CLLocationCoordinate2D?, String?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                completionHandler(nil, error.localizedDescription)
                return
            }
            if let mapItem = response?.mapItems.first {
                completionHandler(mapItem.placemark.coordinate, nil)
            } else {
                completionHandler(nil, "No location found")
            }
        }
    }
}

extension LocationSearchManager: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results
    }
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        self.searchResults = []
    }
}

