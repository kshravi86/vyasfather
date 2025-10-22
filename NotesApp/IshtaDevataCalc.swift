import Foundation

struct IshtaDevataResultModel {
    let atmakaraka: String
    let akRasiSign: String
    let akNavamsaSign: String
    let twelfthFromAKNavamsaSign: String
    let twelfthLord: String
    let twelfthOccupant: String?
    let ishtaDeterminingPlanet: String
    let deity: String
    let suggestion: String

    let amatyakaraka: String
    let amkRasiSign: String
    let amkNavamsaSign: String
    let sixthFromAMKNavamsaSign: String
    let sixthLord: String
    let sixthOccupant: String?
    let palanaDeterminingPlanet: String
    let palanaDeity: String
    let palanaSuggestion: String
}

enum IshtaDevataCalcIOS {
    private static func signIndex(from name: String) -> Int { ZodiacSign.from(name: name)?.rawValue ?? 0 }
    private static func signName(from idx: Int) -> String { ZodiacSign(rawValue: ((idx % 12)+12)%12)?.displayName ?? "Aries" }

    private static func modality(of idx: Int) -> Modality {
        let s = ((idx % 12)+12)%12
        switch s {
        case 0,3,6,9: return .movable
        case 1,4,7,10: return .fixed
        default: return .dual
        }
    }

    private static func navamsaSignIndex(for absLongitude: Double) -> Int {
        let lon = (absLongitude.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
        let sign = Int(floor(lon / 30.0))
        let within = lon - Double(sign) * 30.0
        let nmIndex = Int(floor(within / (30.0/9.0))) // 0..8
        let start: Int
        switch modality(of: sign) {
        case .movable: start = sign
        case .fixed: start = (sign + 8) % 12 // 9th from sign
        case .dual: start = (sign + 4) % 12 // 5th from sign
        }
        return (start + nmIndex) % 12
    }

    private static func signLord(of idx: Int) -> String {
        switch ((idx%12)+12)%12 {
        case 0: return "Mars"
        case 1: return "Venus"
        case 2: return "Mercury"
        case 3: return "Moon"
        case 4: return "Sun"
        case 5: return "Mercury"
        case 6: return "Venus"
        case 7: return "Mars"
        case 8: return "Jupiter"
        case 9: return "Saturn"
        case 10: return "Saturn"
        default: return "Jupiter"
        }
    }

    private static func deity(of planet: String) -> String {
        switch planet.lowercased() {
        case "sun": return "Shiva"
        case "moon": return "Gauri/Parvati"
        case "mars": return "Subrahmanya/Skanda"
        case "mercury": return "Vishnu"
        case "jupiter": return "Narayana"
        case "venus": return "Lakshmi"
        case "saturn": return "Hanuman/Kala Bhairava"
        case "rahu": return "Durga/Pratyangira/Kalaratri"
        case "ketu": return "Ganesha"
        default: return "—"
        }
    }

    private static func suggestion(for deity: String) -> String {
        switch deity {
        case "Shiva": return "Maha Mrityunjaya mantra, Rudra Abhishekam, Mondays"
        case "Gauri/Parvati": return "Devi stotras, fasting on Mondays/Fridays"
        case "Subrahmanya/Skanda": return "Skanda Shashti vrata, Subrahmanya stotra"
        case "Vishnu": return "Vishnu Sahasranama, Ekadashi upavasa"
        case "Narayana": return "Narayana Kavacham, Guru mantra on Thursdays"
        case "Lakshmi": return "Shri Suktam, Fridays, charitable acts"
        case "Hanuman/Kala Bhairava": return "Hanuman Chalisa/Tailabhishekam; Bhairava Ashtakam"
        case "Durga/Pratyangira/Kalaratri": return "Chandi/Devi Mahatmyam, Rahu remedies on Saturdays"
        case "Ganesha": return "Ganesha Atharvashirsha, Sankashti Chaturthi"
        default: return "General sattvic practices and japa"
        }
    }

    static func compute(planetPositions: [PlanetPosition]) -> IshtaDevataResultModel? {
        // Chara karakas
        let karakas = JaiminiKarakasCalc.compute(planetPositions: planetPositions, houses: [], includeRahu: false)
        guard let ak = karakas.first else { return nil }
        guard karakas.count > 1 else { return nil }
        let amk = karakas[1]

        // Navamsa signs for all planets
        let d9SignsByPlanet: [String: Int] = Dictionary(uniqueKeysWithValues: planetPositions.map { ($0.name, navamsaSignIndex(for: $0.longitude)) })

        let akD9 = d9SignsByPlanet[ak.planetName] ?? signIndex(from: ak.sign)
        let twelfthFromAK = (akD9 + 11) % 12
        let twelfthLord = signLord(of: twelfthFromAK)
        let twelfthOccupant = planetPositions.first { (d9SignsByPlanet[$0.name] ?? -1) == twelfthFromAK }?.name
        let ishtaPlanet = twelfthOccupant ?? twelfthLord
        let ishtaDeity = deity(of: ishtaPlanet)
        let ishtaSuggestion = suggestion(for: ishtaDeity)

        let amkD9 = d9SignsByPlanet[amk.planetName] ?? signIndex(from: amk.sign)
        let sixthFromAMK = (amkD9 + 5) % 12
        let sixthLord = signLord(of: sixthFromAMK)
        let sixthOccupant = planetPositions.first { (d9SignsByPlanet[$0.name] ?? -1) == sixthFromAMK }?.name
        let palanaPlanet = sixthOccupant ?? sixthLord
        let palanaDeity = deity(of: palanaPlanet)
        let palanaSuggestion = suggestion(for: palanaDeity)

        return IshtaDevataResultModel(
            atmakaraka: ak.planetName,
            akRasiSign: ak.sign,
            akNavamsaSign: signName(from: akD9),
            twelfthFromAKNavamsaSign: signName(from: twelfthFromAK),
            twelfthLord: twelfthLord,
            twelfthOccupant: twelfthOccupant,
            ishtaDeterminingPlanet: ishtaPlanet,
            deity: ishtaDeity,
            suggestion: ishtaSuggestion,
            amatyakaraka: amk.planetName,
            amkRasiSign: amk.sign,
            amkNavamsaSign: signName(from: amkD9),
            sixthFromAMKNavamsaSign: signName(from: sixthFromAMK),
            sixthLord: sixthLord,
            sixthOccupant: sixthOccupant,
            palanaDeterminingPlanet: palanaPlanet,
            palanaDeity: palanaDeity,
            palanaSuggestion: palanaSuggestion
        )
    }
}

