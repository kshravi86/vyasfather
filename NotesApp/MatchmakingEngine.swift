import Foundation

struct MatchProfile {
    let moonNakshatra: String
    let moonSign: String
    let ascendantSign: String?
}

struct MatchCompatibility {
    let score: Int
    let verdict: String
    let summary: String
    let taraNote: String
    let elementNote: String
    let ascendantNote: String
}

enum MatchmakingEngine {
    private static let nakshatraOrder = [
        "Ashwini","Bharani","Krittika","Rohini","Mrigashira","Ardra","Punarvasu","Pushya","Ashlesha",
        "Magha","Purva Phalguni","Uttara Phalguni","Hasta","Chitra","Swati","Vishakha","Anuradha",
        "Jyeshtha","Mula","Purva Ashadha","Uttara Ashadha","Shravana","Dhanishta","Shatabhisha","Purva Bhadrapada","Uttara Bhadrapada","Revati"
    ]

    private static let signOrder = [
        "Aries","Taurus","Gemini","Cancer","Leo","Virgo","Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"
    ]

    static func profile(from positions: [PlanetPosition], ascendant: (sign: String, deg: Int, min: Int)?) -> MatchProfile? {
        guard let moon = positions.first(where: { $0.name == "Moon" }) else { return nil }
        return MatchProfile(
            moonNakshatra: moon.nakshatra,
            moonSign: moon.sign,
            ascendantSign: ascendant?.sign
        )
    }

    static func evaluate(primary: MatchProfile, partner: MatchProfile) -> MatchCompatibility {
        let tara = taraNote(primary: primary, partner: partner)
        let element = elementNote(primary: primary, partner: partner)
        let ascNote = ascendantNote(primary: primary, partner: partner)

        let base = 50
        let rawScore = base + tara.delta + element.delta + ascNote.delta
        let clampedScore = max(0, min(100, rawScore))
        let verdict: String
        if clampedScore >= 75 {
            verdict = "Strong harmony"
        } else if clampedScore >= 60 {
            verdict = "Balanced potential"
        } else {
            verdict = "Needs conscious effort"
        }

        let summary = "Moon: \(primary.moonNakshatra) & \(partner.moonNakshatra) | Asc: \(primary.ascendantSign ?? "-") & \(partner.ascendantSign ?? "-")"

        return MatchCompatibility(
            score: clampedScore,
            verdict: verdict,
            summary: summary,
            taraNote: tara.note,
            elementNote: element.note,
            ascendantNote: ascNote.note
        )
    }

    private static func taraNote(primary: MatchProfile, partner: MatchProfile) -> (delta: Int, note: String) {
        guard let aIndex = nakshatraOrder.firstIndex(of: primary.moonNakshatra),
              let bIndex = nakshatraOrder.firstIndex(of: partner.moonNakshatra) else {
            return (0, "Tara: unknown nakshatra order")
        }
        let distance = (bIndex - aIndex + 27) % 27
        let step = distance == 0 ? 27 : distance
        let mod = step % 9
        switch mod {
        case 1, 4, 7:
            return (12, "Tara: favourable rhythm (step \(step))")
        case 2, 5, 8:
            return (6, "Tara: workable harmony (step \(step))")
        case 0, 3, 6:
            return (-8, "Tara: sensitive combination (step \(step))")
        default:
            return (0, "Tara: neutral flow")
        }
    }

    private static func elementNote(primary: MatchProfile, partner: MatchProfile) -> (delta: Int, note: String) {
        let elementMap: [String: String] = [
            "Aries": "Fire", "Leo": "Fire", "Sagittarius": "Fire",
            "Taurus": "Earth", "Virgo": "Earth", "Capricorn": "Earth",
            "Gemini": "Air", "Libra": "Air", "Aquarius": "Air",
            "Cancer": "Water", "Scorpio": "Water", "Pisces": "Water"
        ]
        guard let primaryElement = elementMap[primary.moonSign], let partnerElement = elementMap[partner.moonSign] else {
            return (0, "Elements: unknown")
        }
        let pair = Set([primaryElement, partnerElement])
        if primaryElement == partnerElement {
            return (10, "Elements: same element (\(primaryElement)) binds easily")
        }
        if pair == Set(["Fire", "Air"]) || pair == Set(["Earth", "Water"]) {
            return (8, "Elements: complementary flow (\(primaryElement) + \(partnerElement))")
        }
        if pair == Set(["Fire", "Water"]) || pair == Set(["Air", "Earth"]) {
            return (-6, "Elements: contrasting flow (\(primaryElement) + \(partnerElement))")
        }
        return (2, "Elements: neutral blend (\(primaryElement) + \(partnerElement))")
    }

    private static func ascendantNote(primary: MatchProfile, partner: MatchProfile) -> (delta: Int, note: String) {
        guard let aAsc = primary.ascendantSign, let bAsc = partner.ascendantSign,
              let aIndex = signOrder.firstIndex(of: aAsc), let bIndex = signOrder.firstIndex(of: bAsc) else {
            return (0, "Ascendants: awaiting partner chart")
        }
        let diff = min((aIndex - bIndex + 12) % 12, (bIndex - aIndex + 12) % 12)
        if diff == 0 || diff == 4 || diff == 8 {
            return (8, "Ascendants: supportive angles (\(aAsc) & \(bAsc))")
        }
        if diff == 6 {
            return (-5, "Ascendants: opposing axis (\(aAsc) & \(bAsc))")
        }
        return (3, "Ascendants: neutral blend (\(aAsc) & \(bAsc))")
    }
}
