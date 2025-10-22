import Foundation

struct KarakaEntryModel: Identifiable {
    let id = UUID()
    let rank: Int
    let karakaName: String
    let planetName: String
    let degreeInSign: Double
    let absoluteDegree: Double
    let sign: String
    let house: Int?
}

enum JaiminiKarakasCalc {
    static let labels7 = [
        "Atmakaraka",
        "Amatyakaraka",
        "Bhratrikaraka",
        "Matrikaraka",
        "Putrakaraka",
        "Gnatikaraka",
        "Darakaraka",
    ]

    static func compute(planetPositions: [PlanetPosition], houses: [(index: Int, sign: String, deg: Int, min: Int)], includeRahu: Bool = false) -> [KarakaEntryModel] {
        let coreNames = ["Sun","Moon","Mercury","Venus","Mars","Jupiter","Saturn"]
        var list = planetPositions.filter { coreNames.contains($0.name) }
        if includeRahu, let rahu = planetPositions.first(where: { $0.name == "Rahu" }) {
            list.append(rahu)
        }
        func degInSign(_ abs: Double) -> Double { let x = abs.truncatingRemainder(dividingBy: 30.0); return x < 0 ? x + 30.0 : x }
        let ranked = list.map { p -> (PlanetPosition, Double, Double) in
            let ins = degInSign(p.longitude)
            let score = (p.name == "Rahu") ? (30.0 - ins) : ins
            return (p, score, ins)
        }.sorted { a, b in a.1 > b.1 }

        // Optional: derive house index from cusps if available
        let cusps: [Double] = houses.sorted { $0.index < $1.index }.map { signDegMinToAbs(sign: $0.sign, deg: $0.deg, min: $0.min) }
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

    private static func normalize360(_ x: Double) -> Double { let y = fmod(x, 360.0); return y < 0 ? y + 360.0 : y }
    private static func signDegMinToAbs(sign: String, deg: Int, min: Int) -> Double {
        let idx: Int = ZodiacSign.from(name: sign)?.rawValue ?? 0
        return Double(idx) * 30.0 + Double(deg) + Double(min)/60.0
    }
    private static func inArc(_ lon: Double, _ start: Double, _ end: Double) -> Bool {
        let s = normalize360(start), e = normalize360(end)
        if s <= e { return lon >= s && lon < e }
        return lon >= s || lon < e
    }
}

