import Foundation

struct ArudhaEntryModel: Identifiable {
    let id = UUID()
    let house: Int
    let houseSign: String
    let lord: String
    let lordSign: String
    let lordHouse: Int
    let padaHouse: Int
    let padaSign: String
}

enum JaiminiArudhaCalc {
    private static let signLord: [ZodiacSign: String] = [
        .aries: "Mars", .taurus: "Venus", .gemini: "Mercury", .cancer: "Moon",
        .leo: "Sun", .virgo: "Mercury", .libra: "Venus", .scorpio: "Mars",
        .sagittarius: "Jupiter", .capricorn: "Saturn", .aquarius: "Saturn", .pisces: "Jupiter"
    ]

    private static func advance(_ house: Int, _ steps: Int) -> Int {
        let z = ((house - 1 + steps) % 12 + 12) % 12
        return z + 1
    }

    static func compute(planetPositions: [PlanetPosition], houses: [(index: Int, sign: String, deg: Int, min: Int)]) -> [ArudhaEntryModel] {
        // Map planet -> house (derive using cusps), and house -> sign
        let cusps: [Double] = houses.sorted { $0.index < $1.index }.map { signDegMinToAbs(sign: $0.sign, deg: $0.deg, min: $0.min) }
        func houseIndex(for abs: Double) -> Int {
            guard cusps.count == 12 else { return 1 }
            let lon = normalize360(abs)
            for i in 0..<12 {
                let a = cusps[i]
                let b = cusps[(i+1)%12]
                if inArc(lon, a, b) { return i+1 }
            }
            return 1
        }
        let byPlanetHouse: [String: Int] = Dictionary(uniqueKeysWithValues: planetPositions.map { ($0.name, houseIndex(for: $0.longitude)) })
        let houseToSign: [Int: ZodiacSign] = Dictionary(uniqueKeysWithValues: houses.map { ($0.index, ZodiacSign.from(name: $0.sign) ?? .aries) })

        var result: [ArudhaEntryModel] = []
        for h in 1...12 {
            guard let sign = houseToSign[h], let lordName = signLord[sign] else { continue }
            let lordHouse = byPlanetHouse[lordName] ?? 1
            let same = (lordHouse == h)
            let seventh = (lordHouse == advance(h, 6))
            var padaHouse: Int
            if same || seventh {
                padaHouse = advance(h, 9)
            } else {
                let distanceInclusive = ((lordHouse - h + 12) % 12) + 1
                padaHouse = advance(lordHouse, distanceInclusive - 1)
            }
            if padaHouse == h || padaHouse == advance(h, 6) {
                padaHouse = advance(padaHouse, 9)
            }
            let padaSign = houseToSign[padaHouse] ?? .aries
            let lordSign = houseToSign[lordHouse] ?? .aries
            result.append(ArudhaEntryModel(
                house: h,
                houseSign: sign.displayName,
                lord: lordName,
                lordSign: lordSign.displayName,
                lordHouse: lordHouse,
                padaHouse: padaHouse,
                padaSign: padaSign.displayName
            ))
        }
        return result
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

