import Foundation
import CoreLocation

struct PlanetPosition: Identifiable {
    let id = UUID()
    let name: String
    let longitude: Double // sidereal ecliptic longitude in degrees [0,360)
    let sign: String
    let deg: Int
    let min: Int
    let nakshatra: String
    let pada: Int
}

final class PlanetaryCalculator {
    // Swiss Ephemeris flags (hardcoded constants)
    private let SEFLG_SWIEPH = 2
    private let SEFLG_SIDEREAL = 0x40000 // 262144

    // Planet codes (Swiss Ephemeris)
    private let SE_SUN = 0
    private let SE_MOON = 1
    private let SE_MERCURY = 2
    private let SE_VENUS = 3
    private let SE_MARS = 4
    private let SE_JUPITER = 5
    private let SE_SATURN = 6
    private let SE_MEAN_NODE = 10

    private let signs = ["Aries","Taurus","Gemini","Cancer","Leo","Virgo","Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"]
    private let nakshatras = [
        "Ashwini","Bharani","Krittika","Rohini","Mrigashira","Ardra","Punarvasu","Pushya","Ashlesha",
        "Magha","Purva Phalguni","Uttara Phalguni","Hasta","Chitra","Swati","Vishakha","Anuradha",
        "Jyeshtha","Mula","Purva Ashadha","Uttara Ashadha","Shravana","Dhanishta","Shatabhisha","Purva Bhadrapada","Uttara Bhadrapada","Revati"
    ]

    func compute(date: Date, time: Date, coordinate: CLLocationCoordinate2D) -> [PlanetPosition] {
        // Merge date + time using Asia/Kolkata for Indian coords; else current
        let tz: TimeZone = isInIndia(coordinate) ? TimeZone(identifier: "Asia/Kolkata") ?? .current : .current
        let merged = merge(date: date, time: time, in: tz)
        let jdUT = julianDayUT(from: merged, timeZone: tz)

        // Prefer Swiss Ephemeris file-based accuracy if data files are present in bundle
        if let dataPath = Bundle.main.path(forResource: "SwissEph", ofType: nil) {
            swe_bridged_set_ephe_path(dataPath)
        }
        swe_bridged_set_sidereal_lahiri()
        // Use only Swiss Ephemeris (file-based) with Lahiri
        let flags = SEFLG_SWIEPH | SEFLG_SIDEREAL

        let planets: [(String, Int)] = [
            ("Sun", SE_SUN), ("Moon", SE_MOON), ("Mercury", SE_MERCURY), ("Venus", SE_VENUS),
            ("Mars", SE_MARS), ("Jupiter", SE_JUPITER), ("Saturn", SE_SATURN), ("Rahu", SE_MEAN_NODE)
        ]

        var results: [PlanetPosition] = planets.compactMap { name, code in
            var rc: Int32 = 0
            let lon = normalize360(swe_bridged_longitude_ut(Int32(code), jdUT, Int32(flags), &rc))
            guard rc == 0 else { return nil }
            let (signName, d, m) = toSignDegMin(lon)
            let (nak, pada) = toNakshatra(lon)
            return PlanetPosition(name: name, longitude: lon, sign: signName, deg: d, min: m, nakshatra: nak, pada: pada)
        }

        // Ketu = Rahu + 180
        if let rahu = results.first(where: { $0.name == "Rahu" }) {
            let ketuLon = normalize360(rahu.longitude + 180.0)
            let (signName, d, m) = toSignDegMin(ketuLon)
            let (nak, pada) = toNakshatra(ketuLon)
            let ketu = PlanetPosition(name: "Ketu", longitude: ketuLon, sign: signName, deg: d, min: m, nakshatra: nak, pada: pada)
            results.append(ketu)
        }

        return results
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

    private func julianDayUT(from localDate: Date, timeZone: TimeZone) -> Double {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents(in: timeZone, from: localDate)
        let y = comps.year ?? 2000
        let mo = comps.month ?? 1
        let d = comps.day ?? 1
        let hourLocal = Double(comps.hour ?? 0) + Double(comps.minute ?? 0)/60.0 + Double(comps.second ?? 0)/3600.0
        let tzHours = Double(timeZone.secondsFromGMT(for: localDate)) / 3600.0
        let hourUT = hourLocal - tzHours
        return swe_bridged_julday_gregorian(Int32(y), Int32(mo), Int32(d), hourUT)
    }

    private func normalize360(_ x: Double) -> Double { let y = fmod(x, 360.0); return y < 0 ? y + 360.0 : y }

    private func toSignDegMin(_ lon: Double) -> (String, Int, Int) {
        let signIndex = Int(floor(lon / 30.0)) % 12
        let signStart = Double(signIndex) * 30.0
        let within = lon - signStart
        let deg = Int(floor(within))
        let min = Int(floor((within - Double(deg)) * 60.0 + 0.5))
        return (signs[signIndex], deg, min)
    }

    private func toNakshatra(_ lon: Double) -> (String, Int) {
        let segment = 13.3333333333 // 13°20'
        let idx = Int(floor(lon / segment)) % 27
        let rem = lon - Double(idx) * segment
        let pada = Int(floor(rem / (segment / 4.0))) + 1 // 1..4
        return (nakshatras[idx], max(1, min(4, pada)))
    }

    private func isInIndia(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 6 && coord.latitude <= 36 && coord.longitude >= 68 && coord.longitude <= 98
    }
}
