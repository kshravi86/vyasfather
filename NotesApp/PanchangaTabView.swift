import SwiftUI
import CoreLocation

struct PanchangaTabView: View {
    let dateOfBirth: Date
    let timeOfBirth: Date
    let coordinate: CLLocationCoordinate2D?
    let planetPositions: [PlanetPosition]
    @Environment(\.colorScheme) private var colorScheme

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
                if let coord = coordinate {
                    let tz: TimeZone = isInIndia(coord) ? (TimeZone(identifier: "Asia/Kolkata") ?? .current) : .current
                    let dt = merge(date: dateOfBirth, time: timeOfBirth, in: tz)
                    let p = PanchangaCalcIOS.compute(planetPositions: planetPositions, dateTime: dt, timeZone: tz)
                    VStack(spacing: 14) {
                        sectionCard(title: "Tithi", icon: "moonphase.first.quarter", color: .indigo) {
                            labeledRow("Tithi", p.tithi)
                            labeledRow("Group", p.tithiGroup)
                        }
                        sectionCard(title: "Vara & Nakshatra", icon: "calendar", color: .orange) {
                            labeledRow("Vara", p.vara)
                            labeledRow("Nakshatra", p.nakshatra)
                        }
                        sectionCard(title: "Yoga", icon: "seal", color: .teal) {
                            labeledRow("Yoga", p.yoga)
                            labeledRow("Lord", p.yogaLord)
                        }
                        sectionCard(title: "Karana", icon: "triangle.lefthalf.filled", color: .purple) {
                            labeledRow("Karana", p.karana)
                            labeledRow("Lord", p.karanaLord)
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Waiting for location...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Panchanga")
            .background(WaterTheme.gradient(for: colorScheme))
        }
    }

    @ViewBuilder
    private func sectionCard<T: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> T) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.headline)
            }
            content()
        }
        .cardBackground()
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

