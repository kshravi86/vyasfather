import SwiftUI
import CoreLocation

struct LagnasTabView: View {
    let dateOfBirth: Date
    let timeOfBirth: Date
    let coordinate: CLLocationCoordinate2D?
    let planetPositions: [PlanetPosition]
    let ascendant: (sign: String, deg: Int, min: Int)?
    @Environment(\.colorScheme) private var colorScheme
    private let calculator = PlanetaryCalculator()

    private func merge(date: Date, time: Date, in tz: TimeZone) -> Date {
        let cal = Calendar(identifier: .gregorian)
        var dcmp = cal.dateComponents(in: tz, from: date)
        let tcmp = cal.dateComponents(in: tz, from: time)
        dcmp.hour = tcmp.hour
        dcmp.minute = tcmp.minute
        dcmp.second = tcmp.second
        return cal.date(from: dcmp) ?? date
    }

    var body: some View {
        NavigationView {
            Group {
                if let coord = coordinate {
                    let tz = TimeZone.current
                    let dt = merge(date: dateOfBirth, time: timeOfBirth, in: tz)
                    let natalAscAbs: Double = {
                        if let a = ascendant, let sIdx = ZodiacSign.from(name: a.sign)?.rawValue {
                            return Double(sIdx) * 30.0 + Double(a.deg) + Double(a.min)/60.0
                        }
                        return 0.0
                    }()
                    let gl = SpecialLagnasCalc.ghatikaLagna(date: dt, tz: tz, coord: coord, calculator: calculator)
                    let hl = SpecialLagnasCalc.horaLagna(date: dt, tz: tz, coord: coord, natalAscAbs: natalAscAbs, calculator: calculator)
                    let hlj = SpecialLagnasCalc.horaLagnaJaimini(date: dt, tz: tz, coord: coord, calculator: calculator)
                    let indu = SpecialLagnasCalc.induLagna(planetPositions: planetPositions, ascSignName: ascendant?.sign ?? "Aries")

                    ScrollView {
                        VStack(spacing: 14) {
                            sectionCard(title: "Ghatika Lagna", icon: "clock.badge.checkmark", color: .orange) {
                                if let gl = gl {
                                    labeledRow("Sign", gl.sign)
                                } else { Text("Unavailable") .foregroundColor(.secondary).font(.caption) }
                            }
                            sectionCard(title: "Hora Lagna", icon: "clock", color: .teal) {
                                if let hl = hl {
                                    labeledRow("Sign", hl.sign)
                                } else { Text("Unavailable").foregroundColor(.secondary).font(.caption) }
                            }
                            sectionCard(title: "Hora Lagna (Jaimini)", icon: "clock.arrow.circlepath", color: .indigo) {
                                if let h = hlj {
                                    labeledRow("Sign", h.sign)
                                } else { Text("Unavailable").foregroundColor(.secondary).font(.caption) }
                            }
                            sectionCard(title: "Indu Lagna", icon: "indianrupeesign.circle", color: .purple) {
                                if let i = indu {
                                    labeledRow("Sign", i.sign)
                                } else { Text("Unavailable").foregroundColor(.secondary).font(.caption) }
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Waiting for location...").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Special Lagnas")
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
        HStack { Text(title); Spacer(); Text(value).font(.caption).foregroundColor(.secondary) }
    }
}
