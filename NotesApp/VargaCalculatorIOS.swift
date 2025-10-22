import Foundation

enum VargaIOS {
    case d9
}

struct D9Entry: Identifiable {
    let id = UUID()
    let planet: String
    let sign: String
    let house: Int
}

enum VargaCalculatorIOS {
    private static func normalize360(_ x: Double) -> Double { let y = fmod(x, 360.0); return y < 0 ? y + 360.0 : y }

    private static func signIndex(for lon: Double) -> Int { Int(floor(normalize360(lon) / 30.0)) }

    private static func modality(of signIndex: Int) -> Modality {
        switch ((signIndex%12)+12)%12 {
        case 0,3,6,9: return .movable
        case 1,4,7,10: return .fixed
        default: return .dual
        }
    }

    static func mapLongitudeToD9SignIndex(_ lon: Double) -> Int {
        let deg = normalize360(lon)
        let sIdx = signIndex(for: deg)
        let inSign = deg - Double(sIdx) * 30.0
        let part = Int(floor(inSign / (30.0/9.0)))
        let startOffset: Int = {
            switch modality(of: sIdx) {
            case .movable: return 0
            case .fixed: return 8 // 9th from sign
            case .dual: return 4 // 5th from sign
            }
        }()
        return (sIdx + startOffset + part) % 12
    }

    static func computeD9(planetPositions: [PlanetPosition], ascendant: (sign: String, deg: Int, min: Int)?) -> (ascSign: String, entries: [D9Entry]) {
        let ascAbs: Double = {
            if let a = ascendant, let sIdx = ZodiacSign.from(name: a.sign)?.rawValue {
                return Double(sIdx) * 30.0 + Double(a.deg) + Double(a.min)/60.0
            }
            return 0.0
        }()
        let d9AscIdx = mapLongitudeToD9SignIndex(ascAbs)
        let ascSignName = ZodiacSign(rawValue: d9AscIdx)?.displayName ?? "Aries"
        let entries: [D9Entry] = planetPositions.map { p in
            let d9Idx = mapLongitudeToD9SignIndex(p.longitude)
            let house = 1 + ((d9Idx - d9AscIdx + 12) % 12)
            return D9Entry(planet: p.name, sign: ZodiacSign(rawValue: d9Idx)?.displayName ?? "Aries", house: house)
        }
        return (ascSignName, entries)
    }
}

