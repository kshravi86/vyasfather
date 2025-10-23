import SwiftUI
import CoreLocation

struct DashaTabView: View {
    let dateOfBirth: Date
    let timeOfBirth: Date
    let coordinate: CLLocationCoordinate2D?
    let planetPositions: [PlanetPosition]

    private func isInIndia(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 6 && coord.latitude <= 36 && coord.longitude >= 68 && coord.longitude <= 98
    }

    private func merge(date: Date, time: Date, in tz: TimeZone) -> Date {
        let cal = Calendar(identifier: .gregorian)
        var dcmp = cal.dateComponents(in: tz, from: date)
        let tcmp = cal.dateComponents(in: tz, from: time)
        dcmp.hour = tcmp.hour
        dcmp.minute = tcmp.minute
        dcmp.second = tcmp.second
        dcmp.nanosecond = 0
        return cal.date(from: dcmp) ?? date
    }

    var body: some View {
        NavigationView {
            Group {
                if let moon = planetPositions.first(where: { $0.name == "Moon" }), let coord = coordinate {
                    let tz: TimeZone = isInIndia(coord) ? (TimeZone(identifier: "Asia/Kolkata") ?? .current) : .current
                    let mergedDate = merge(date: dateOfBirth, time: timeOfBirth, in: tz)
                    let details = BirthDetails(name: nil, dateTime: mergedDate, timeZone: tz, latitude: coord.latitude, longitude: coord.longitude)
                    let mahadashas = VimshottariDashaCalculator.calculateVimshottariDasha(birthDetails: details, moonSiderealLongitude: moon.longitude)
                    DashaView(mahadashas: mahadashas, planetPositions: planetPositions)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Computing Moon position...")
                            .foregroundColor(CosmicTheme.secondaryText)
                    }
                }
            }
            .navigationTitle("Dasha")
        }
    }
}
