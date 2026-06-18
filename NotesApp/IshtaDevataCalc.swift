import Foundation

/// Output from the Ishta Devata and Palana Devata calculation.
///
/// Both deities are derived via the Navamsha (D9) chart using Jaimini Karakas:
///  - **Ishta Devata** comes from the Atmakaraka (soul significator).
///  - **Palana Devata** comes from the Amatyakaraka (career/mind significator).
struct IshtaDevataResultModel {
    // MARK: Atmakaraka → Ishta Devata path
    let atmakaraka: String               // Planet with highest degree in any sign (AK)
    let akRasiSign: String               // AK's sign in the Rasi (D1) chart
    let akNavamsaSign: String            // AK's sign in the Navamsha (D9) chart
    let twelfthFromAKNavamsaSign: String // 12th house counted from AK's D9 sign
    let twelfthLord: String              // Sign lord of the 12th-from-AK sign
    let twelfthOccupant: String?         // Planet occupying the 12th D9 house, if any
    let ishtaDeterminingPlanet: String   // Occupant preferred; else the lord
    let deity: String                    // Deity associated with the determining planet
    let suggestion: String               // Practical worship / mantra recommendation

    // MARK: Amatyakaraka → Palana Devata path
    let amatyakaraka: String             // Planet with 2nd-highest degree (AMK)
    let amkRasiSign: String
    let amkNavamsaSign: String
    let sixthFromAMKNavamsaSign: String  // 6th house counted from AMK's D9 sign
    let sixthLord: String
    let sixthOccupant: String?
    let palanaDeterminingPlanet: String
    let palanaDeity: String
    let palanaSuggestion: String
}

/// Derives the Ishta Devata (personal deity) and Palana Devata (sustaining deity)
/// from the Navamsha chart using Jaimini Chara Karakas.
///
/// **Algorithm**
///
/// 1. Rank all 7 planets by their degree within their sign (highest = Atmakaraka).
/// 2. In the Navamsha (D9), locate the Atmakaraka's sign.
/// 3. Count 12 houses forward from that sign. The sign lord of that 12th sign is the
///    default Ishta Planet. If any planet physically occupies the 12th D9 house, it
///    takes precedence (occupant overrides lord).
/// 4. Map the Ishta Planet to a deity and a set of worship suggestions.
/// 5. Repeat steps 2–4 for the Amatyakaraka using the **6th** house to get the Palana Devata.
enum IshtaDevataCalcIOS {

    // MARK: - Sign index helpers

    private static func signIndex(from name: String) -> Int { ZodiacSign.from(name: name)?.rawValue ?? 0 }
    private static func signName(from idx: Int) -> String { ZodiacSign(rawValue: ((idx % 12)+12)%12)?.displayName ?? "Aries" }

    /// Sign modality: Movable (Chara), Fixed (Sthira), or Dual (Dwiswabhava).
    /// Used to determine the Navamsha starting sign for each zodiac sign.
    private static func modality(of idx: Int) -> Modality {
        let s = ((idx % 12)+12)%12
        switch s {
        case 0,3,6,9:   return .movable  // Aries, Cancer, Libra, Capricorn
        case 1,4,7,10:  return .fixed    // Taurus, Leo, Scorpio, Aquarius
        default:        return .dual     // Gemini, Virgo, Sagittarius, Pisces
        }
    }

    /// Returns the 0-based Navamsha sign index for a given absolute sidereal longitude.
    ///
    /// The Navamsha divides each 30° sign into 9 equal parts (3°20' each).
    /// The starting sign for each pada depends on the sign's modality:
    ///  - Movable: Navamsha 1 starts from the sign itself.
    ///  - Fixed: Navamsha 1 starts from the 9th sign from the sign.
    ///  - Dual: Navamsha 1 starts from the 5th sign from the sign.
    private static func navamsaSignIndex(for absLongitude: Double) -> Int {
        let lon = (absLongitude.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
        let sign = Int(floor(lon / 30.0))           // Which of the 12 signs?
        let within = lon - Double(sign) * 30.0       // Degrees within that sign
        let nmIndex = Int(floor(within / (30.0/9.0))) // Which of the 9 Navamsha divisions?
        let start: Int
        switch modality(of: sign) {
        case .movable: start = sign               // Navamsha 1 = same as Rasi sign
        case .fixed:   start = (sign + 8) % 12   // Navamsha 1 = 9th from Rasi sign
        case .dual:    start = (sign + 4) % 12   // Navamsha 1 = 5th from Rasi sign
        }
        return (start + nmIndex) % 12
    }

    /// Standard sign lord (dispositor) for sign index 0–11.
    private static func signLord(of idx: Int) -> String {
        switch ((idx%12)+12)%12 {
        case 0:  return "Mars"     // Aries
        case 1:  return "Venus"    // Taurus
        case 2:  return "Mercury"  // Gemini
        case 3:  return "Moon"     // Cancer
        case 4:  return "Sun"      // Leo
        case 5:  return "Mercury"  // Virgo
        case 6:  return "Venus"    // Libra
        case 7:  return "Mars"     // Scorpio
        case 8:  return "Jupiter"  // Sagittarius
        case 9:  return "Saturn"   // Capricorn
        case 10: return "Saturn"   // Aquarius
        default: return "Jupiter"  // Pisces
        }
    }

    // MARK: - Deity and suggestion maps

    /// Maps a ruling planet to its primary presiding deity.
    private static func deity(of planet: String) -> String {
        switch planet.lowercased() {
        case "sun":     return "Shiva"
        case "moon":    return "Gauri/Parvati"
        case "mars":    return "Subrahmanya/Skanda"
        case "mercury": return "Vishnu"
        case "jupiter": return "Narayana"
        case "venus":   return "Lakshmi"
        case "saturn":  return "Hanuman/Kala Bhairava"
        case "rahu":    return "Durga/Pratyangira/Kalaratri"
        case "ketu":    return "Ganesha"
        default:        return "—"
        }
    }

    /// Returns a practical set of worship/sadhana recommendations for a given deity.
    private static func suggestion(for deity: String) -> String {
        switch deity {
        case "Shiva":                       return "Maha Mrityunjaya mantra, Rudra Abhishekam, Mondays"
        case "Gauri/Parvati":              return "Devi stotras, fasting on Mondays/Fridays"
        case "Subrahmanya/Skanda":         return "Skanda Shashti vrata, Subrahmanya stotra"
        case "Vishnu":                     return "Vishnu Sahasranama, Ekadashi upavasa"
        case "Narayana":                   return "Narayana Kavacham, Guru mantra on Thursdays"
        case "Lakshmi":                    return "Shri Suktam, Fridays, charitable acts"
        case "Hanuman/Kala Bhairava":      return "Hanuman Chalisa/Tailabhishekam; Bhairava Ashtakam"
        case "Durga/Pratyangira/Kalaratri":return "Chandi/Devi Mahatmyam, Rahu remedies on Saturdays"
        case "Ganesha":                    return "Ganesha Atharvashirsha, Sankashti Chaturthi"
        default:                           return "General sattvic practices and japa"
        }
    }

    // MARK: - Main computation

    /// Derives both the Ishta Devata and the Palana Devata for a birth chart.
    ///
    /// Returns `nil` if fewer than 2 Jaimini Karakas can be determined
    /// (requires at least Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn in `planetPositions`).
    static func compute(planetPositions: [PlanetPosition], ascendant: (sign: String, deg: Int, min: Int)?) -> IshtaDevataResultModel? {
        // Rank planets by degree-in-sign to identify Atmakaraka (rank 1) and Amatyakaraka (rank 2).
        let karakas = JaiminiKarakasCalc.compute(planetPositions: planetPositions, houses: [], includeRahu: false)
        guard karakas.count >= 2 else { return nil }
        let ak  = karakas[0]   // Atmakaraka: highest degree in sign
        let amk = karakas[1]   // Amatyakaraka: second-highest degree in sign

        // Compute the Navamsha (D9) chart to get each planet's D9 sign and house.
        let d9 = VargaCalculatorIOS.computeD9(planetPositions: planetPositions, ascendant: ascendant)
        let d9SignsByPlanet: [String: Int] = Dictionary(uniqueKeysWithValues: d9.entries.map {
            ($0.planet, (ZodiacSign.from(name: $0.sign)?.rawValue ?? 0))
        })
        let d9HouseByPlanet: [String: Int] = Dictionary(uniqueKeysWithValues: d9.entries.map {
            ($0.planet, $0.house)
        })

        // --- Ishta Devata (from Atmakaraka) ---
        // 1. Find AK's Navamsha sign index.
        let akD9 = d9SignsByPlanet[ak.planetName] ?? signIndex(from: ak.sign)
        // 2. 12th from AK's D9 sign (0-based: add 11, then mod 12).
        let twelfthFromAK = (akD9 + 11) % 12
        let twelfthLord = signLord(of: twelfthFromAK)
        // 3. Check if any planet physically occupies the 12th D9 house from AK's D9 house.
        let akHouse = d9HouseByPlanet[ak.planetName] ?? 1
        let targetHouseAk = ((akHouse + 10) % 12) + 1  // house number 1..12
        let twelfthOccupant = d9.entries.first { $0.house == targetHouseAk }?.planet
        // Occupant takes precedence over the lord.
        let ishtaPlanet  = twelfthOccupant ?? twelfthLord
        let ishtaDeity   = deity(of: ishtaPlanet)
        let ishtaSuggestion = suggestion(for: ishtaDeity)

        // --- Palana Devata (from Amatyakaraka) ---
        // Same logic but uses the 6th house (not 12th) from AMK's D9 position.
        let amkD9 = d9SignsByPlanet[amk.planetName] ?? signIndex(from: amk.sign)
        let sixthFromAMK = (amkD9 + 5) % 12
        let sixthLord = signLord(of: sixthFromAMK)
        let amkHouse = d9HouseByPlanet[amk.planetName] ?? 1
        let targetHouseAmk = ((amkHouse + 4) % 12) + 1
        let sixthOccupant = d9.entries.first { $0.house == targetHouseAmk }?.planet
        let palanaPlanet  = sixthOccupant ?? sixthLord
        let palanaDeity   = deity(of: palanaPlanet)
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
