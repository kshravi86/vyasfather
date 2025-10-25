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
            ScrollView { // ADDED SCROLLVIEW
                Group {
                    if let coord = coordinate {
                        let tz: TimeZone = isInIndia(coord) ? (TimeZone(identifier: "Asia/Kolkata") ?? .current) : .current
                        let dt = merge(date: dateOfBirth, time: timeOfBirth, in: tz)
                        let p = PanchangaCalcIOS.compute(planetPositions: planetPositions, dateTime: dt, timeZone: tz)
                        VStack(spacing: 14) {
                            sectionCard(title: "Tithi", icon: "moonphase.first.quarter", color: .indigo) { color in
                                labeledRow("Tithi", p.tithi)
                                labeledRow("Group", p.tithiGroup)
                                if let meaning = tithiGroupMeaning(p.tithiGroup), !meaning.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(alignment: .top, spacing: 6) {
                                            Image(systemName: "info.circle")
                                                .foregroundColor(color.opacity(0.7))
                                            Text("\(p.tithiGroup): ")
                                                .font(.footnote.bold())
                                                .foregroundColor(CosmicTheme.text)
                                            + Text(meaning)
                                                .font(.footnote.italic())
                                                .foregroundColor(CosmicTheme.secondaryText)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Spacer(minLength: 0)
                                        }
                                    }
                                    .padding(10)
                                    .background(color.opacity(0.1))
                                    .cornerRadius(8)
                                    .accessibilityLabel("Tithi group meaning: \(p.tithiGroup). \(meaning)")
                                }
                            }
                            sectionCard(title: "Vara & Nakshatra", icon: "calendar", color: .orange) { _ in
                                labeledRow("Vara", p.vara)
                                labeledRow("Nakshatra", p.nakshatra)
                            }
                            sectionCard(title: "Yoga", icon: "seal", color: .teal) { _ in
                                labeledRow("Yoga", p.yoga)
                                labeledRow("Lord", p.yogaLord)
                            }
                            sectionCard(title: "Karana", icon: "triangle.lefthalf.filled", color: .purple) { _ in
                                labeledRow("Karana", p.karana)
                                labeledRow("Lord", p.karanaLord)
                            }
                        }
                        .padding()
                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Waiting for location...")
                                .foregroundColor(CosmicTheme.secondaryText)
                        }
                    }
                }
            } // END SCROLLVIEW
            .navigationTitle("Panchanga")
            .background(CosmicTheme.gradient(for: colorScheme))
        }
    }

    // ... (rest of the file)

    @ViewBuilder
    private func sectionCard<T: View>(title: String, icon: String, color: Color, @ViewBuilder content: (_ color: Color) -> T) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.title2.bold()).foregroundColor(CosmicTheme.text)
            }
            .padding(.bottom, 5)
            content(color)
        }
        .cardBackground()
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(CosmicTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.headline.bold())
                .foregroundColor(CosmicTheme.text)
        }
    }

    private func tithiGroupMeaning(_ group: String) -> String? {
        switch group {
        case "Nanda":
            return "Joy, happiness, pleasure"
        case "Bhadra":
            return "Auspiciousness, welfare, prosperity"
        case "Jaya":
            return "Victory, success, overcoming obstacles"
        case "Rikta":
            return "Emptiness, removal, clearing away"
        case "Poorna":
            return "Fulfilment, completion, abundance"
        default:
            return nil
        }
    }
}
