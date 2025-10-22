import Foundation

struct YogaIOSResult: Identifiable {
    let id = UUID()
    let name: String
    let description: String
}

enum YogaDetectorIOS {
    private static let signLord: [ZodiacSign: String] = [
        .aries: "Mars", .taurus: "Venus", .gemini: "Mercury", .cancer: "Moon",
        .leo: "Sun", .virgo: "Mercury", .libra: "Venus", .scorpio: "Mars",
        .sagittarius: "Jupiter", .capricorn: "Saturn", .aquarius: "Saturn", .pisces: "Jupiter"
    ]

    private static let exaltation: [String: ZodiacSign] = [
        "Sun": .aries, "Moon": .taurus, "Mars": .capricorn, "Mercury": .virgo,
        "Jupiter": .cancer, "Venus": .pisces, "Saturn": .libra
    ]

    private static let debilitation: [String: ZodiacSign] = [
        "Sun": .libra, "Moon": .scorpio, "Mars": .cancer, "Mercury": .pisces,
        "Jupiter": .capricorn, "Venus": .virgo, "Saturn": .aries
    ]

    struct PlanetPos { let name: String; let sign: ZodiacSign; let house: Int }

    static func detect(planetPositions: [PlanetPosition], houses: [(index: Int, sign: String, deg: Int, min: Int)]) -> [YogaIOSResult] {
        let chartPlanets = mapPlanetsToHouses(planetPositions: planetPositions, houses: houses)
        guard !chartPlanets.isEmpty else { return [] }
        var list: [YogaIOSResult] = []
        list.append(contentsOf: detectPanchaMahapurusha(chartPlanets))
        if let gk = detectGajaKesari(chartPlanets) { list.append(gk) }
        if let ba = detectBudhaAditya(chartPlanets) { list.append(ba) }
        if let cm = detectChandraMangala(chartPlanets) { list.append(cm) }
        list.append(contentsOf: detectAnaphaSunaphaDurdhara(chartPlanets))
        list.append(contentsOf: detectRajaYogaSimple(chartPlanets, houses: houses))
        list.append(contentsOf: detectDhanaYogaSimple(chartPlanets, houses: houses))
        list.append(contentsOf: detectParivartanaSafe(chartPlanets))
        list.append(contentsOf: detectViparitaRaja(chartPlanets, houses: houses))
        if let kd = detectKemadruma(chartPlanets) { list.append(kd) }
        list.append(contentsOf: detectNeechaBhanga(chartPlanets))
        list.append(contentsOf: NabhasaDetectorIOS.detect(chartPlanets))
        return list
    }

    // MARK: - Mapping helpers
    private static func mapPlanetsToHouses(planetPositions: [PlanetPosition], houses: [(index: Int, sign: String, deg: Int, min: Int)]) -> [PlanetPos] {
        guard houses.count == 12 else { return [] }
        let cusps: [Double] = houses.sorted { $0.index < $1.index }.map { h in
            let si = ZodiacSign.from(name: h.sign)?.rawValue ?? 0
            return Double(si) * 30.0 + Double(h.deg) + Double(h.min)/60.0
        }
        func houseFor(longitude: Double) -> Int {
            for i in 0..<12 {
                let a = cusps[i]
                var b = cusps[(i+1) % 12]
                var L = longitude
                var low = a
                if b < a { b += 360.0 }
                if L < a { L += 360.0; low = a }
                if L >= low && L < b { return i + 1 }
            }
            return 1
        }
        var mapped: [PlanetPos] = []
        for p in planetPositions {
            guard let z = ZodiacSign.from(name: p.sign) else { continue }
            let h = houseFor(longitude: p.longitude)
            mapped.append(PlanetPos(name: p.name, sign: z, house: h))
        }
        return mapped
    }

    // MARK: - Yogas
    private static func detectPanchaMahapurusha(_ planets: [PlanetPos]) -> [YogaIOSResult] {
        var list: [YogaIOSResult] = []
        let kendra: Set<Int> = [1,4,7,10]
        func isOwn(_ planet: String, _ sign: ZodiacSign) -> Bool { signLord[sign] == planet }
        func isExalted(_ planet: String, _ sign: ZodiacSign) -> Bool { exaltation[planet] == sign }
        for p in planets where ["Mars","Mercury","Jupiter","Venus","Saturn"].contains(p.name) {
            guard kendra.contains(p.house) else { continue }
            let strong = isOwn(p.name, p.sign) || isExalted(p.name, p.sign)
            guard strong else { continue }
            let desc = "\(p.name) strong (own/exalted) in a Kendra house (\(p.sign.displayName), H\(p.house))."
            let name: String = {
                switch p.name {
                case "Mars": return "Ruchaka Yoga"
                case "Mercury": return "Bhadra Yoga"
                case "Jupiter": return "Hamsa Yoga"
                case "Venus": return "Malavya Yoga"
                case "Saturn": return "Shasha Yoga"
                default: return "Mahapurusha"
                }
            }()
            list.append(YogaIOSResult(name: name, description: desc))
        }
        return list
    }

    private static func detectGajaKesari(_ planets: [PlanetPos]) -> YogaIOSResult? {
        guard let moon = planets.first(where: { $0.name == "Moon" }), let jup = planets.first(where: { $0.name == "Jupiter" }) else { return nil }
        let diff = (jup.house - moon.house + 12) % 12
        if [0,3,6,9].contains(diff) {
            return YogaIOSResult(
                name: "Gaja Kesari Yoga",
                description: "Jupiter is in a Kendra from the Moon (Moon: H\(moon.house), Jupiter: H\(jup.house))."
            )
        }
        return nil
    }

    private static func detectBudhaAditya(_ planets: [PlanetPos]) -> YogaIOSResult? {
        guard let sun = planets.first(where: { $0.name == "Sun" }), let merc = planets.first(where: { $0.name == "Mercury" }) else { return nil }
        guard sun.house == merc.house else { return nil }
        return YogaIOSResult(name: "Budha Aditya Yoga", description: "Sun and Mercury are conjoined in House H\(sun.house) (\(sun.sign.displayName)).")
    }

    private static func detectChandraMangala(_ planets: [PlanetPos]) -> YogaIOSResult? {
        guard let moon = planets.first(where: { $0.name == "Moon" }), let mars = planets.first(where: { $0.name == "Mars" }) else { return nil }
        guard moon.house == mars.house else { return nil }
        return YogaIOSResult(name: "Chandra-Mangala Yoga", description: "Moon and Mars are conjoined in House H\(moon.house) (\(moon.sign.displayName)).")
    }

    private static func detectAnaphaSunaphaDurdhara(_ planets: [PlanetPos]) -> [YogaIOSResult] {
        guard let moon = planets.first(where: { $0.name == "Moon" }) else { return [] }
        let second = (moon.house % 12) + 1
        let twelfth = ((moon.house + 10) % 12) + 1
        let allowed: Set<String> = ["Mercury","Venus","Mars","Jupiter","Saturn"]
        let inSecond = planets.filter { $0.house == second && allowed.contains($0.name) }
        let inTwelfth = planets.filter { $0.house == twelfth && allowed.contains($0.name) }
        var out: [YogaIOSResult] = []
        if !inSecond.isEmpty && !inTwelfth.isEmpty {
            let left = inTwelfth.map { $0.name }.joined(separator: ", ")
            let right = inSecond.map { $0.name }.joined(separator: ", ")
            out.append(YogaIOSResult(name: "Durdhara Yoga", description: "Planets flank the Moon: 12th (H\(twelfth): \(left)) and 2nd (H\(second): \(right))."))
            return out
        }
        if !inTwelfth.isEmpty {
            let list = inTwelfth.map { $0.name }.joined(separator: ", ")
            out.append(YogaIOSResult(name: "Anapha Yoga", description: "Planets in 12th from Moon (H\(twelfth)): \(list)."))
        }
        if !inSecond.isEmpty {
            let list = inSecond.map { $0.name }.joined(separator: ", ")
            out.append(YogaIOSResult(name: "Sunapha Yoga", description: "Planets in 2nd from Moon (H\(second)): \(list)."))
        }
        return out
    }

    private static func detectRajaYogaSimple(_ planets: [PlanetPos], houses: [(index: Int, sign: String, deg: Int, min: Int)]) -> [YogaIOSResult] {
        let kendras: Set<Int> = [1,4,7,10]
        let trikonas: Set<Int> = [1,5,9]
        let houseSign: [Int: ZodiacSign] = Dictionary(uniqueKeysWithValues: houses.map { h in (h.index, ZodiacSign.from(name: h.sign) ?? .aries) })
        func lordOfHouse(_ h: Int) -> String { signLord[houseSign[h]!]! }
        let kendraLords = Set(kendras.map(lordOfHouse))
        let trikonaLords = Set(trikonas.map(lordOfHouse))
        let byPlanet = Dictionary(uniqueKeysWithValues: planets.map { ($0.name, $0) })
        var out: [YogaIOSResult] = []
        for t in trikonaLords {
            for k in kendraLords {
                if let tp = byPlanet[t], let kp = byPlanet[k], tp.house == kp.house {
                    let tHouse = houseOfFixed(trikonas, planet: t, houseSign: houseSign)
                    let kHouse = houseOfFixed(kendras, planet: k, houseSign: houseSign)
                    out.append(YogaIOSResult(name: "Raja Yoga (conjunction)", description: "Lord of \(tHouse) and lord of \(kHouse) conjoined in H\(tp.house)."))
                }
            }
        }
        return out
    }

    private static func detectDhanaYogaSimple(_ planets: [PlanetPos], houses: [(index: Int, sign: String, deg: Int, min: Int)]) -> [YogaIOSResult] {
        let houseSign: [Int: ZodiacSign] = Dictionary(uniqueKeysWithValues: houses.map { h in (h.index, ZodiacSign.from(name: h.sign) ?? .aries) })
        func lordOfHouse(_ h: Int) -> String { signLord[houseSign[h]!]! }
        let lord2 = lordOfHouse(2)
        let lord11 = lordOfHouse(11)
        let byPlanet = Dictionary(uniqueKeysWithValues: planets.map { ($0.name, $0) })
        var out: [YogaIOSResult] = []
        if let p2 = byPlanet[lord2], let p11 = byPlanet[lord11], p2.house == p11.house {
            out.append(YogaIOSResult(name: "Dhana Yoga (2nd & 11th lords)", description: "Lords of 2nd and 11th are conjoined in H\(p2.house)."))
        }
        if let p2 = byPlanet[lord2], p2.house == 11 {
            out.append(YogaIOSResult(name: "Dhana Yoga (2L in 11H)", description: "2nd lord is placed in the 11th house."))
        }
        if let p11 = byPlanet[lord11], p11.house == 2 {
            out.append(YogaIOSResult(name: "Dhana Yoga (11L in 2H)", description: "11th lord is placed in the 2nd house."))
        }
        return out
    }

    private static func detectViparitaRaja(_ planets: [PlanetPos], houses: [(index: Int, sign: String, deg: Int, min: Int)]) -> [YogaIOSResult] {
        let dusthanas: Set<Int> = [6,8,12]
        let houseSign: [Int: ZodiacSign] = Dictionary(uniqueKeysWithValues: houses.map { h in (h.index, ZodiacSign.from(name: h.sign) ?? .aries) })
        func lordOfHouse(_ h: Int) -> String { signLord[houseSign[h]!]! }
        let byPlanet = Dictionary(uniqueKeysWithValues: planets.map { ($0.name, $0) })
        var out: [YogaIOSResult] = []
        for h in [6,8,12] {
            let lord = lordOfHouse(h)
            if let pos = byPlanet[lord], dusthanas.contains(pos.house), pos.house != h {
                out.append(YogaIOSResult(name: "Viparita Raja Yoga", description: "Lord of \(h)th in \(pos.house)th (dusthana-in-dusthana)."))
            }
        }
        return out
    }

    private static func detectKemadruma(_ planets: [PlanetPos]) -> YogaIOSResult? {
        guard let moon = planets.first(where: { $0.name == "Moon" }) else { return nil }
        let neighbors = planets.filter { $0.name != "Moon" && ($0.house == ((moon.house % 12) + 1) || $0.house == (((moon.house + 10) % 12) + 1) || $0.house == moon.house) }
        if neighbors.isEmpty {
            return YogaIOSResult(name: "Kemadruma Yoga", description: "No planets conjoined with Moon or in 2nd/12th from Moon (base rule).")
        }
        return nil
    }

    private static func detectNeechaBhanga(_ planets: [PlanetPos]) -> [YogaIOSResult] {
        let byPlanet = Dictionary(uniqueKeysWithValues: planets.map { ($0.name, $0) })
        let kendras: Set<Int> = [1,4,7,10]
        var out: [YogaIOSResult] = []
        for p in planets {
            if let debSign = debilitation[p.name], p.sign == debSign {
                if let dispositor = signLord[debSign], let lordPos = byPlanet[dispositor], kendras.contains(lordPos.house) {
                    out.append(YogaIOSResult(name: "Neecha Bhanga Raja Yoga", description: "\(p.name) debilitated in \(p.sign.displayName), cancelled by dispositor in Kendra (H\(lordPos.house))."))
                }
            }
        }
        return out
    }

    private static func detectParivartanaSafe(_ planets: [PlanetPos]) -> [YogaIOSResult] {
        var out: [YogaIOSResult] = []
        let byName = Dictionary(uniqueKeysWithValues: planets.map { ($0.name, $0) })
        let names = planets.map { $0.name }
        for i in 0..<names.count {
            for j in (i+1)..<names.count {
                let a = names[i]; let b = names[j]
                guard let pa = byName[a], let pb = byName[b] else { continue }
                let lordA = signLord[pa.sign]
                let lordB = signLord[pb.sign]
                if lordA == b && lordB == a {
                    let desc = "Mutual exchange between \(a) and \(b) (signs \(pa.sign.displayName) <-> \(pb.sign.displayName))."
                    out.append(YogaIOSResult(name: "Parivartana Yoga", description: desc))
                }
            }
        }
        return out
    }

    // Helpers
    private static func houseOfFixed(_ pool: Set<Int>, planet: String, houseSign: [Int: ZodiacSign]) -> String {
        for h in pool.sorted() {
            if let lord = signLord[houseSign[h] ?? .aries], lord == planet { return String(h) }
        }
        return "?"
    }
}

enum NabhasaDetectorIOS {
    static func detect(_ planets: [YogaDetectorIOS.PlanetPos]) -> [YogaIOSResult] {
        var list: [YogaIOSResult] = []
        list.append(contentsOf: detectAsraya(planets))
        if let dala = detectDala(planets) { list.append(dala) }
        if let sankhya = detectSankhya(planets) { list.append(sankhya) }
        return list
    }

    private static func coreSeven(_ planets: [YogaDetectorIOS.PlanetPos]) -> [YogaDetectorIOS.PlanetPos] {
        return planets.filter { ["Sun","Moon","Mercury","Venus","Mars","Jupiter","Saturn"].contains($0.name) }
    }
    private static func isMovable(_ s: ZodiacSign) -> Bool { return [.aries,.cancer,.libra,.capricorn].contains(s) }
    private static func isFixed(_ s: ZodiacSign) -> Bool { return [.taurus,.leo,.scorpio,.aquarius].contains(s) }
    private static func isDual(_ s: ZodiacSign) -> Bool { return [.gemini,.virgo,.sagittarius,.pisces].contains(s) }

    private static func detectAsraya(_ chart: [YogaDetectorIOS.PlanetPos]) -> [YogaIOSResult] {
        let core = coreSeven(chart)
        guard !core.isEmpty else { return [] }
        let allMov = core.allSatisfy { isMovable($0.sign) }
        let allFix = core.allSatisfy { isFixed($0.sign) }
        let allDual = core.allSatisfy { isDual($0.sign) }
        let summary = core.map { "\($0.name)(\($0.sign.displayName))" }.joined(separator: ", ")
        if allMov { return [YogaIOSResult(name: "Rajju (Āsraya)", description: "All seven classical planets occupy movable signs: \(summary).") ] }
        if allFix { return [YogaIOSResult(name: "Musala (Āsraya)", description: "All seven classical planets occupy fixed signs: \(summary).") ] }
        if allDual { return [YogaIOSResult(name: "Nala (Āsraya)", description: "All seven classical planets occupy dual signs: \(summary).") ] }
        return []
    }

    private static func detectDala(_ chart: [YogaDetectorIOS.PlanetPos]) -> YogaIOSResult? {
        let core = coreSeven(chart)
        let kendras: Set<Int> = [1,4,7,10]
        let inKendra = core.filter { kendras.contains($0.house) }
        guard !inKendra.isEmpty else { return nil }
        let benefics: Set<String> = ["Jupiter","Venus","Mercury","Moon"]
        let malefics: Set<String> = ["Sun","Mars","Saturn"]
        let allBenefic = inKendra.allSatisfy { benefics.contains($0.name) }
        let allMalefic = inKendra.allSatisfy { malefics.contains($0.name) }
        let positions = inKendra.sorted { $0.house < $1.house }.map { "H\($0.house):\($0.name)" }.joined(separator: ", ")
        if allBenefic { return YogaIOSResult(name: "Mala (Dala)", description: "Benefics occupy Kendra houses only: \(positions).") }
        if allMalefic { return YogaIOSResult(name: "Sarpa (Dala)", description: "Malefics occupy Kendra houses only: \(positions).") }
        return nil
    }

    private static func detectSankhya(_ chart: [YogaDetectorIOS.PlanetPos]) -> YogaIOSResult? {
        let core = coreSeven(chart)
        guard !core.isEmpty else { return nil }
        let bySign = Dictionary(grouping: core, by: { $0.sign })
        let count = bySign.keys.count
        let name: String? = {
            switch count {
            case 1: return "Gola (Sankhya)"
            case 2: return "Yuga (Sankhya)"
            case 3: return "Shoola (Sankhya)"
            case 4: return "Kedara (Sankhya)"
            case 5: return "Pasha (Sankhya)"
            case 6: return "Dama (Sankhya)"
            case 7: return "Veena (Sankhya)"
            default: return nil
            }
        }()
        guard let nm = name else { return nil }
        let distribution = bySign.keys.sorted { $0.rawValue < $1.rawValue }
            .map { s in
                let plist = (bySign[s] ?? []).map { $0.name }.joined(separator: ", ")
                return "\(s.displayName): \(plist)"
            }.joined(separator: ", ")
        return YogaIOSResult(name: nm, description: "Seven planets span \(count) sign(s). Distribution: \(distribution).")
    }
}

