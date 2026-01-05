import Foundation
import CoreLocation

enum AngleFormatter {
    private static let degreeSymbol = "\u{00B0}"

    static func format(degrees: Int, minutes: Int) -> String {
        let paddedMinutes = String(format: "%02d", minutes)
        return "\(degrees)\(degreeSymbol)\(paddedMinutes)'"
    }

    static func describe(sign: String, degrees: Int, minutes: Int) -> String {
        "\(sign) \(format(degrees: degrees, minutes: minutes))"
    }

    static func describe(position: PlanetPosition) -> String {
        describe(sign: position.sign, degrees: position.deg, minutes: position.min)
    }

    static func coordinate(_ value: Double, positiveHemisphere: String, negativeHemisphere: String) -> String {
        let hemisphere = value >= 0 ? positiveHemisphere : negativeHemisphere
        let magnitude = abs(value)
        return String(format: "%.2f%@ %@", magnitude, degreeSymbol, hemisphere)
    }
}

/// Sidereal ecliptic coordinates for a single body returned by Swiss Ephemeris.
/// The struct keeps the raw longitude plus pre-split, presentation-ready parts
/// so downstream UI does not repeat angle math.
struct PlanetPosition: Identifiable {
    let id = UUID()
    let name: String
    let longitude: Double // sidereal ecliptic longitude in degrees [0,360)
    let sign: String
    let deg: Int
    let min: Int
    let nakshatra: String
    let pada: Int
    let retrograde: Bool
}

/// Thin wrapper around the Swiss Ephemeris C bridge. Responsible for turning a
/// birth date/time/location into planetary longitudes, ascendant, and Placidus
/// houses. The calculator also carries lightweight diagnostics so the UI can
/// explain when the bundled SwissEph files are missing or misconfigured.
final class PlanetaryCalculator {
    // Swiss Ephemeris flags (hardcoded constants)
    private let SEFLG_SWIEPH = 2               // from swephexp.h
    private let SEFLG_SIDEREAL = 64 * 1024     // 65536, from swephexp.h

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

    // Exposes last calculation error for UI banner
    private(set) var lastError: String? = nil
    // Diagnostics for UI/logs
    private(set) var lastEphePath: String? = nil
    private(set) var epheFilesCount: Int = 0
    private(set) var epheSamples: [String] = []
    private(set) var logs: [String] = []
    private(set) var ascendant: (sign: String, deg: Int, min: Int)? = nil
    private(set) var houses: [(index: Int, sign: String, deg: Int, min: Int)] = []

    /// Computes planetary positions, ascendant, and house cusps using Swiss Ephemeris.
    /// - Parameters:
    ///   - date: Calendar date provided by the user (no time component expected).
    ///   - time: Time-of-day for the birth in the user's local clock.
    ///   - coordinate: Birthplace coordinates used for ascendant/house math.
    ///   - timeZone: Explicit timezone for the birth location. If nil, defaults
    ///               to India (Lahiri) region heuristic or device timezone.
    /// - Returns: Sidereal positions for major bodies plus Rahu/Ketu. Any SwissEph
    ///            failures are recorded in `lastError` and `logs`.
    func compute(date: Date, time: Date, coordinate: CLLocationCoordinate2D, timeZone: TimeZone? = nil) -> [PlanetPosition] {
        lastError = nil
        logs.removeAll(keepingCapacity: true)
        // Merge date + time into a single local moment (explicit TZ wins).
        let tz: TimeZone = timeZone
            ?? (isInIndia(coordinate) ? TimeZone(identifier: "Asia/Kolkata") ?? .current : .current)
        let merged = merge(date: date, time: time, in: tz)
        // Swiss Ephemeris expects a Julian Day in UT.
        let jdUT = julianDayUT(from: merged, timeZone: tz)

        // Prefer Swiss Ephemeris file-based accuracy if data files are present in bundle
        resolveAndSetEphemerisPath()
        swe_bridged_set_sidereal_lahiri()
        // Use only Swiss Ephemeris (file-based) with Lahiri
        let flags = SEFLG_SWIEPH | SEFLG_SIDEREAL
        
        // Primary bodies; Ketu is derived from Rahu after computing positions.
        let planets: [(String, Int)] = [
            ("Sun", SE_SUN), ("Moon", SE_MOON), ("Mercury", SE_MERCURY), ("Venus", SE_VENUS),
            ("Mars", SE_MARS), ("Jupiter", SE_JUPITER), ("Saturn", SE_SATURN), ("Rahu", SE_MEAN_NODE)
        ]

        var hadFailure = false
        var results: [PlanetPosition] = planets.compactMap { name, code in
            var lon: Double = 0
            var spd: Double = 0
            let rc = swe_bridged_calc_lon_speed(Int32(code), jdUT, Int32(flags), &lon, &spd)
            lon = normalize360(lon)
            // Swiss retflag: negative indicates error; non-negative contains flags
            if rc < 0 {
                hadFailure = true
                let line = "ERROR ret=\(rc) for \(name) (code=\(code)) JD_UT=\(String(format: "%.5f", jdUT))"
                print("[SwissEph] \(line)")
                appendLog(line)
                return nil
            }
            let (signName, d, m) = toSignDegMin(lon)
            let (nak, pada) = toNakshatra(lon)
            let isRetro = spd < 0
            // Capture a readable log line for DiagnosticsView.
            let positionDescription = AngleFormatter.describe(sign: signName, degrees: d, minutes: m)
            let retroSuffix = isRetro ? " retrograde" : ""
            let line = "\(name): lon=\(String(format: "%.6f", lon)) sign=\(positionDescription) nak=\(nak) p\(pada)\(retroSuffix) (ret=\(rc))"
            print("[SwissEph] \(line)")
            appendLog(line)
            return PlanetPosition(name: name, longitude: lon, sign: signName, deg: d, min: m, nakshatra: nak, pada: pada, retrograde: isRetro)
        }

        // Ketu is always 180 degrees opposite Rahu in sidereal longitude.
        if let rahu = results.first(where: { $0.name == "Rahu" }) {
            let ketuLon = normalize360(rahu.longitude + 180.0)
            let (signName, d, m) = toSignDegMin(ketuLon)
            let (nak, pada) = toNakshatra(ketuLon)
            let ketu = PlanetPosition(name: "Ketu", longitude: ketuLon, sign: signName, deg: d, min: m, nakshatra: nak, pada: pada, retrograde: true)
            results.append(ketu)
        }

        // Compute Ascendant and Placidus houses
        computeHouses(jdUT: jdUT, coord: coordinate)

        if hadFailure {
            lastError = "Swiss ephemeris lookup failed for one or more bodies. Ensure SwissEph files exist."
            appendLog(lastError!)
        }
        return results
    }

    /// Calculates ascendant and Placidus house cusps for the supplied Julian Day.
    /// The values are cached on the instance for downstream tabs to consume.
    private func computeHouses(jdUT: Double, coord: CLLocationCoordinate2D) {
        houses.removeAll()
        ascendant = nil
        // Swiss Ephemeris fills cusps[1...12] and ascmc[0] (ascendant longitude).
        var cusps = [Double](repeating: 0.0, count: 13)
        var ascmc = [Double](repeating: 0.0, count: 10)
        let rc: Int32 = cusps.withUnsafeMutableBufferPointer { cbuf in
            ascmc.withUnsafeMutableBufferPointer { abuf in
                swe_bridged_houses_placidus(jdUT, coord.latitude, coord.longitude, Int32(SEFLG_SIDEREAL), cbuf.baseAddress, abuf.baseAddress)
            }
        }
        if rc < 0 {
            appendLog("ERROR houses ret=\(rc)")
            return
        }
        let ascLon = normalize360(ascmc[0])
        let (aSign, aD, aM) = toSignDegMin(ascLon)
        ascendant = (aSign, aD, aM)
        // Cusps indices 1..12
        var list: [(Int,String,Int,Int)] = []
        for i in 1...12 {
            let lon = normalize360(cusps[i])
            let (s, d, m) = toSignDegMin(lon)
            list.append((i,s,d,m))
        }
        houses = list
    }

    /// Attempts to locate the bundled SwissEph folder in common bundle paths and
    /// configures the bridge to read ephemeris files from there.
    private func resolveAndSetEphemerisPath() {
        let fm = FileManager.default
        epheFilesCount = 0
        epheSamples = []
        lastEphePath = nil
        // Record metadata so DiagnosticsView can verify packaged data.
        func record(path: String) {
            lastEphePath = path
            if let items = try? fm.contentsOfDirectory(atPath: path) {
                let se1s = items.filter { $0.hasSuffix(".se1") }.sorted()
                epheFilesCount = se1s.count
                epheSamples = Array(se1s.prefix(5))
            }
        }

        if let dataPath = Bundle.main.path(forResource: "SwissEph", ofType: nil) {
            swe_bridged_set_ephe_path(dataPath)
            record(path: dataPath)
            let line = "Using resource path: \(dataPath) files=\(epheFilesCount) samples=\(epheSamples)"
            print("[SwissEph] \(line)")
            appendLog(line)
            return
        }
        if let altURL = Bundle.main.resourceURL?.appendingPathComponent("SwissEph", isDirectory: true),
           fm.fileExists(atPath: altURL.path) {
            swe_bridged_set_ephe_path(altURL.path)
            record(path: altURL.path)
            let line = "Using resourceURL path: \(altURL.path) files=\(epheFilesCount) samples=\(epheSamples)"
            print("[SwissEph] \(line)")
            appendLog(line)
            return
        }
        let guess = (Bundle.main.bundlePath as NSString).appendingPathComponent("SwissEph")
        if fm.fileExists(atPath: guess) {
            swe_bridged_set_ephe_path(guess)
            record(path: guess)
            let line = "Using bundlePath guess: \(guess) files=\(epheFilesCount) samples=\(epheSamples)"
            print("[SwissEph] \(line)")
            appendLog(line)
            return
        }
        let warn = "WARNING: SwissEph folder not found in bundle"
        print("[SwissEph] \(warn)")
        appendLog(warn)
    }

    private func appendLog(_ line: String) {
        logs.append(line)
        // Keep a bounded buffer so diagnostics stay lightweight.
        if logs.count > 200 { logs.removeFirst(logs.count - 200) }
    }

    /// Combines a date-only and time-only input into a single Date in the given
    /// timezone. Swiss Ephemeris expects a single moment, not separated parts.
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

    /// Converts a local date/time into a Julian Day (UT) understood by Swiss Ephemeris.
    private func julianDayUT(from localDate: Date, timeZone: TimeZone) -> Double {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents(in: timeZone, from: localDate)
        let y = comps.year ?? 2000
        let mo = comps.month ?? 1
        let d = comps.day ?? 1
        // Convert local time to UT by subtracting the timezone offset.
        let hourLocal = Double(comps.hour ?? 0) + Double(comps.minute ?? 0)/60.0 + Double(comps.second ?? 0)/3600.0
        let tzHours = Double(timeZone.secondsFromGMT(for: localDate)) / 3600.0
        let hourUT = hourLocal - tzHours
        return swe_bridged_julday_gregorian(Int32(y), Int32(mo), Int32(d), hourUT)
    }

    private func normalize360(_ x: Double) -> Double { let y = fmod(x, 360.0); return y < 0 ? y + 360.0 : y }

    private func toSignDegMin(_ lon: Double) -> (String, Int, Int) {
        // Each sign spans 30 degrees; minutes are rounded to the nearest minute.
        let signIndex = Int(floor(lon / 30.0)) % 12
        let signStart = Double(signIndex) * 30.0
        let within = lon - signStart
        let deg = Int(floor(within))
        let min = Int(floor((within - Double(deg)) * 60.0 + 0.5))
        return (signs[signIndex], deg, min)
    }

    private func toNakshatra(_ lon: Double) -> (String, Int) {
        // 27 nakshatras, each 13 degrees 20 minutes (13.3333).
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
