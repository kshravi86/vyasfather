import Foundation

struct PushkaraEntry: Identifiable {
    let id = UUID()
    let planet: String
    let isPushkara: Bool
    let d9Sign: String?
}

enum PushkaraUtils {
    private static func inSignDegree(from longitude: Double) -> Double {
        let norm = fmod(longitude, 360.0) + (longitude < 0 ? 360.0 : 0.0)
        var d = fmod(norm, 30.0)
        if d < 0 { d += 30.0 }
        return d
    }

    private static func signIndex(from longitude: Double) -> Int {
        let norm = fmod(longitude, 360.0)
        let x = norm < 0 ? norm + 360.0 : norm
        return Int(floor(x / 30.0))
    }

    private static func element(for signIndex: Int) -> String { // fire, earth, air, water
        switch ((signIndex % 12) + 12) % 12 {
        case 0, 4, 8: return "fire"
        case 1, 5, 9: return "earth"
        case 2, 6, 10: return "air"
        default: return "water"
        }
    }

    private static let seg: Double = 30.0 / 9.0 // 3°20′ = 3.333333…

    // windows are [start, end) in degrees within sign
    private static func pushkaraWindows(for element: String) -> [(Double, Double)] {
        switch element {
        case "fire":
            return [(20.0, 20.0 + 3.0*seg), (20.0 + 2.0*seg, 30.0)] // 20–23°20′, 26°40′–30
        case "earth":
            return [(2.0*seg, 10.0), (4.0*seg, 5.0*seg)] // 6°40′–10, 13°20′–16°40′
        case "air":
            return [(5.0*seg, 20.0), (7.0*seg, 8.0*seg)] // 16°40′–20, 23°20′–26°40′
        default: // water
            return [(0.0, seg), (2.0*seg, 10.0)] // 0–3°20′, 6°40′–10
        }
    }

    static func evaluate(planetPositions: [PlanetPosition]) -> [PushkaraEntry] {
        return planetPositions.map { p in
            let sIdx = signIndex(from: p.longitude)
            let elem = element(for: sIdx)
            let d = inSignDegree(from: p.longitude)
            let windows = pushkaraWindows(for: elem)
            let ok = windows.contains { (lo, hi) in d >= lo && d < hi }
            let d9Sign: String? = ok ? (ZodiacSign(rawValue: VargaCalculatorIOS.mapLongitudeToD9SignIndex(p.longitude))?.displayName ?? nil) : nil
            return PushkaraEntry(planet: p.name, isPushkara: ok, d9Sign: d9Sign)
        }
    }

    static func evaluateLagna(sign: String, deg: Int, min: Int) -> PushkaraEntry? {
        guard let sIdx = ZodiacSign.from(name: sign)?.rawValue else { return nil }
        let abs = Double(sIdx) * 30.0 + Double(deg) + Double(min)/60.0
        let elem = element(for: sIdx)
        let d = inSignDegree(from: abs)
        let windows = pushkaraWindows(for: elem)
        let ok = windows.contains { (lo, hi) in d >= lo && d < hi }
        let d9Sign: String? = ok ? (ZodiacSign(rawValue: VargaCalculatorIOS.mapLongitudeToD9SignIndex(abs))?.displayName ?? nil) : nil
        return PushkaraEntry(planet: "Lagna", isPushkara: ok, d9Sign: d9Sign)
    }
}
