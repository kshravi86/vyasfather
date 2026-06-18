import Foundation

/// A single Jaimini Karaka entry: the ranked planet with its sign position and
/// optional Placidus house placement.
struct KarakaEntryModel: Identifiable {
    let id = UUID()
    let rank: Int           // 1 = Atmakaraka, 2 = Amatyakaraka, etc.
    let karakaName: String  // e.g. "Atmakaraka", "Amatyakaraka"
    let planetName: String
    let degreeInSign: Double    // Degrees within the planet's sign (0–30°)
    let absoluteDegree: Double  // Sidereal ecliptic longitude (0–360°)
    let sign: String
    let house: Int?         // Placidus house number, nil if house cusps not supplied
}

/// Computes the 7 Jaimini Chara Karakas from a set of planetary positions.
///
/// **Karaka scoring rule**
///
/// Each planet's degree within its current sign determines its karaka rank:
///  - For all planets *except* Rahu: score = degrees within sign (higher = higher rank).
///  - For Rahu: score = 30° − degrees within sign (Rahu counts "backwards" from the end
///    of the sign, reflecting its retrograde nature).
///
/// Planets are sorted descending by score, and the top 7 are labelled with the
/// standard 7-karaka sequence (Atmakaraka through Darakaraka).
///
/// If `includeRahu` is true an 8-karaka scheme is used; otherwise 7-karaka.
enum JaiminiKarakasCalc {

    /// Labels for the standard 7-karaka scheme, in rank order.
    static let labels7 = [
        "Atmakaraka",    // AK  — soul / self
        "Amatyakaraka",  // AMK — intellect / profession
        "Bhratrikaraka", // BK  — siblings
        "Matrikaraka",   // MK  — mother
        "Putrakaraka",   // PK  — children
        "Gnatikaraka",   // GK  — competition / health
        "Darakaraka",    // DK  — spouse / partnership
    ]

    /// Returns the ordered list of Karaka entries for a birth chart.
    ///
    /// - Parameters:
    ///   - planetPositions: Sidereal planetary positions from `PlanetaryCalculator`.
    ///   - houses: Optional Placidus house cusps used to assign a house number to each planet.
    ///             Pass an empty array if house data is unavailable.
    ///   - includeRahu: When `true`, Rahu is added to the scoring pool (8-karaka scheme).
    ///                  Default is `false` (classical 7-karaka scheme).
    static func compute(planetPositions: [PlanetPosition], houses: [(index: Int, sign: String, deg: Int, min: Int)], includeRahu: Bool = false) -> [KarakaEntryModel] {
        let coreNames = ["Sun","Moon","Mercury","Venus","Mars","Jupiter","Saturn"]
        var list = planetPositions.filter { coreNames.contains($0.name) }
        if includeRahu, let rahu = planetPositions.first(where: { $0.name == "Rahu" }) {
            list.append(rahu)
        }

        /// Degree within the current sign, normalised to [0, 30).
        func degInSign(_ abs: Double) -> Double {
            let x = abs.truncatingRemainder(dividingBy: 30.0)
            return x < 0 ? x + 30.0 : x
        }

        // Score each planet. Rahu scores from the sign's end; all others from the start.
        let ranked = list.map { p -> (PlanetPosition, Double, Double) in
            let ins = degInSign(p.longitude)
            let score = (p.name == "Rahu") ? (30.0 - ins) : ins
            return (p, score, ins)
        }.sorted { a, b in a.1 > b.1 }  // descending by score

        // Build house-lookup closure from the provided cusps.
        let cusps: [Double] = houses
            .sorted { $0.index < $1.index }
            .map { signDegMinToAbs(sign: $0.sign, deg: $0.deg, min: $0.min) }

        func houseIndex(for abs: Double) -> Int? {
            guard cusps.count == 12 else { return nil }
            let lon = normalize360(abs)
            for i in 0..<12 {
                let a = cusps[i]
                let b = cusps[(i+1)%12]
                if inArc(lon, a, b) { return i+1 }
            }
            return nil
        }

        return ranked.prefix(labels7.count).enumerated().map { idx, t in
            let p = t.0
            return KarakaEntryModel(
                rank: idx + 1,
                karakaName: labels7[idx],
                planetName: p.name,
                degreeInSign: t.2,
                absoluteDegree: p.longitude,
                sign: p.sign,
                house: houseIndex(for: p.longitude)
            )
        }
    }

    // MARK: - Private helpers

    private static func normalize360(_ x: Double) -> Double {
        let y = fmod(x, 360.0)
        return y < 0 ? y + 360.0 : y
    }

    /// Converts a sign + degree + minute position into an absolute ecliptic longitude.
    private static func signDegMinToAbs(sign: String, deg: Int, min: Int) -> Double {
        let idx: Int = ZodiacSign.from(name: sign)?.rawValue ?? 0
        return Double(idx) * 30.0 + Double(deg) + Double(min)/60.0
    }

    /// Returns true if `lon` lies within the arc [start, end) on the circle.
    /// Handles wrap-around (e.g. start = 350°, end = 10°).
    private static func inArc(_ lon: Double, _ start: Double, _ end: Double) -> Bool {
        let s = normalize360(start), e = normalize360(end)
        if s <= e { return lon >= s && lon < e }
        return lon >= s || lon < e
    }
}
