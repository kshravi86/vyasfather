import Foundation

enum ChartGender: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"

    var id: String { rawValue }
}

struct AshtakootaItem: Identifiable {
    let id: String
    let name: String
    let points: Double
    let maxPoints: Double
    let note: String
}

struct AshtakootaResult {
    let total: Double
    let maxTotal: Double
    let items: [AshtakootaItem]
    let note: String?
}

struct MatchProfile {
    let moonNakshatra: String
    let moonSign: String
    let ascendantSign: String?
    let marsSign: String?
    let venusSign: String?

    init(
        moonNakshatra: String,
        moonSign: String,
        ascendantSign: String?,
        marsSign: String? = nil,
        venusSign: String? = nil
    ) {
        self.moonNakshatra = moonNakshatra
        self.moonSign = moonSign
        self.ascendantSign = ascendantSign
        self.marsSign = marsSign
        self.venusSign = venusSign
    }
}

struct MatchCompatibility {
    let score: Int
    let verdict: String
    let summary: String
    let taraNote: String
    let elementNote: String
    let ascendantNote: String
    let marsVenusNote: String?
    let ashtakoota: AshtakootaResult?
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
            ascendantSign: ascendant?.sign,
            marsSign: positions.first(where: { $0.name == "Mars" })?.sign,
            venusSign: positions.first(where: { $0.name == "Venus" })?.sign
        )
    }

    static func evaluate(primary: MatchProfile, partner: MatchProfile, primaryGender: ChartGender, partnerGender: ChartGender) -> MatchCompatibility {
        let tara = taraNote(primary: primary, partner: partner)
        let element = elementNote(primary: primary, partner: partner)
        let ascNote = ascendantNote(primary: primary, partner: partner)
        let marsVenus = marsVenusNote(primary: primary, partner: partner)
        let ashtakoota = ashtakoota(primary: primary, partner: partner, primaryGender: primaryGender, partnerGender: partnerGender)

        // Score = base + weighted deltas from tara, element, and ascendant alignment.
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

        // Summary shown on the UI cards for quick scanning.
        let summary = "Moon: \(primary.moonNakshatra) & \(partner.moonNakshatra) | Asc: \(primary.ascendantSign ?? "-") & \(partner.ascendantSign ?? "-")"

        return MatchCompatibility(
            score: clampedScore,
            verdict: verdict,
            summary: summary,
            taraNote: tara.note,
            elementNote: element.note,
            ascendantNote: ascNote.note,
            marsVenusNote: marsVenus,
            ashtakoota: ashtakoota
        )
    }

    private static func taraNote(primary: MatchProfile, partner: MatchProfile) -> (delta: Int, note: String) {
        guard let aIndex = nakshatraOrder.firstIndex(of: primary.moonNakshatra),
              let bIndex = nakshatraOrder.firstIndex(of: partner.moonNakshatra) else {
            return (0, "Tara: unknown nakshatra order")
        }
        // Tara distance: count forward from primary to partner nakshatra (1..27).
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
        // Element harmony uses the Moon signs (emotional baseline).
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
        // Compare angular distance on the zodiac wheel (0..6).
        let diff = min((aIndex - bIndex + 12) % 12, (bIndex - aIndex + 12) % 12)
        if diff == 0 || diff == 4 || diff == 8 {
            return (8, "Ascendants: supportive angles (\(aAsc) & \(bAsc))")
        }
        if diff == 6 {
            return (-5, "Ascendants: opposing axis (\(aAsc) & \(bAsc))")
        }
        return (3, "Ascendants: neutral blend (\(aAsc) & \(bAsc))")
    }

    private static func marsVenusNote(primary: MatchProfile, partner: MatchProfile) -> String? {
        var lines: [String] = []
        if let primaryMars = primary.marsSign, let partnerVenus = partner.venusSign {
            lines.append(marsVenusLine(
                marsSign: primaryMars,
                venusSign: partnerVenus,
                marsLabel: "Your Mars",
                venusLabel: "Partner Venus"
            ))
        }
        if let partnerMars = partner.marsSign, let primaryVenus = primary.venusSign {
            lines.append(marsVenusLine(
                marsSign: partnerMars,
                venusSign: primaryVenus,
                marsLabel: "Partner Mars",
                venusLabel: "Your Venus"
            ))
        }
        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }

    private static func marsVenusLine(marsSign: String, venusSign: String, marsLabel: String, venusLabel: String) -> String {
        let note = marsVenusChemistry(marsSign: marsSign, venusSign: venusSign)
        return "\(marsLabel) \(marsSign) <-> \(venusLabel) \(venusSign): \(note)"
    }

    private static func marsVenusChemistry(marsSign: String, venusSign: String) -> String {
        if marsSign == venusSign {
            return "strong magnetic pull (same sign)"
        }
        let elementMap: [String: String] = [
            "Aries": "Fire", "Leo": "Fire", "Sagittarius": "Fire",
            "Taurus": "Earth", "Virgo": "Earth", "Capricorn": "Earth",
            "Gemini": "Air", "Libra": "Air", "Aquarius": "Air",
            "Cancer": "Water", "Scorpio": "Water", "Pisces": "Water"
        ]
        guard let marsElement = elementMap[marsSign], let venusElement = elementMap[venusSign] else {
            return "mixed chemistry (unknown elements)"
        }
        if marsElement == venusElement {
            return "natural chemistry (shared element)"
        }
        let pair = Set([marsElement, venusElement])
        if pair == Set(["Fire", "Air"]) || pair == Set(["Earth", "Water"]) {
            return "flowing attraction (complementary elements)"
        }
        if pair == Set(["Fire", "Water"]) || pair == Set(["Air", "Earth"]) {
            return "push-pull tension (contrasting elements)"
        }
        return "mixed chemistry (different elements)"
    }

    private enum Varna: String {
        case brahmin = "Brahmin"
        case kshatriya = "Kshatriya"
        case vaishya = "Vaishya"
        case shudra = "Shudra"

        var rank: Int {
            switch self {
            case .shudra: return 1
            case .vaishya: return 2
            case .kshatriya: return 3
            case .brahmin: return 4
            }
        }
    }

    private enum VashyaCategory: String {
        case chatushpada = "Chatushpada"
        case manava = "Manava"
        case jalachara = "Jalachara"
        case vanachara = "Vanachara"
        case keeta = "Keeta"
    }

    private enum Friendship: String {
        case friend
        case neutral
        case enemy
        case same
    }

    private struct YoniInfo {
        let animal: String
        let sex: String
    }

    private static func ashtakoota(primary: MatchProfile, partner: MatchProfile, primaryGender: ChartGender, partnerGender: ChartGender) -> AshtakootaResult? {
        let ordered = orderedProfiles(primary: primary, partner: partner, primaryGender: primaryGender, partnerGender: partnerGender)
        let items = [
            varnaKoota(groom: ordered.groom, bride: ordered.bride),
            vashyaKoota(groom: ordered.groom, bride: ordered.bride),
            taraKoota(groom: ordered.groom, bride: ordered.bride),
            yoniKoota(groom: ordered.groom, bride: ordered.bride),
            grahaMaitriKoota(groom: ordered.groom, bride: ordered.bride),
            ganaKoota(groom: ordered.groom, bride: ordered.bride),
            bhakootKoota(groom: ordered.groom, bride: ordered.bride),
            nadiKoota(groom: ordered.groom, bride: ordered.bride)
        ]
        let total = items.reduce(0.0) { $0 + $1.points }
        let maxTotal = items.reduce(0.0) { $0 + $1.maxPoints }
        return AshtakootaResult(total: total, maxTotal: maxTotal, items: items, note: ordered.note)
    }

    private static func orderedProfiles(
        primary: MatchProfile,
        partner: MatchProfile,
        primaryGender: ChartGender,
        partnerGender: ChartGender
    ) -> (groom: MatchProfile, bride: MatchProfile, note: String?) {
        if primaryGender == .male && partnerGender == .female {
            return (primary, partner, nil)
        }
        if primaryGender == .female && partnerGender == .male {
            return (partner, primary, nil)
        }
        return (primary, partner, "Directional kootas treat Primary as male when genders match.")
    }

    private static func varnaKoota(groom: MatchProfile, bride: MatchProfile) -> AshtakootaItem {
        guard let groomVarna = varna(for: groom.moonSign),
              let brideVarna = varna(for: bride.moonSign) else {
            return AshtakootaItem(id: "varna", name: "Varna", points: 0, maxPoints: 1, note: "Varna: unknown Moon sign")
        }
        let points = groomVarna.rank >= brideVarna.rank ? 1.0 : 0.0
        let note = "Groom \(groomVarna.rawValue), Bride \(brideVarna.rawValue)"
        return AshtakootaItem(id: "varna", name: "Varna", points: points, maxPoints: 1, note: note)
    }

    private static func vashyaKoota(groom: MatchProfile, bride: MatchProfile) -> AshtakootaItem {
        guard let groomVashya = vashyaCategory(for: groom.moonSign),
              let brideVashya = vashyaCategory(for: bride.moonSign) else {
            return AshtakootaItem(id: "vashya", name: "Vashya", points: 0, maxPoints: 2, note: "Vashya: unknown Moon sign")
        }
        let points = vashyaPoints(male: groomVashya, female: brideVashya)
        let note = "\(groomVashya.rawValue) vs \(brideVashya.rawValue)"
        return AshtakootaItem(id: "vashya", name: "Vashya", points: points, maxPoints: 2, note: note)
    }

    private static func taraKoota(groom: MatchProfile, bride: MatchProfile) -> AshtakootaItem {
        guard let aIndex = nakshatraOrder.firstIndex(of: groom.moonNakshatra),
              let bIndex = nakshatraOrder.firstIndex(of: bride.moonNakshatra) else {
            return AshtakootaItem(id: "tara", name: "Tara", points: 0, maxPoints: 3, note: "Tara: unknown nakshatra")
        }
        // Count forward from groom to bride nakshatra, 1..27.
        let distance = (bIndex - aIndex + 27) % 27
        let step = distance == 0 ? 27 : distance
        let taraIndex = step % 9
        let taraNumber = taraIndex == 0 ? 9 : taraIndex
        let points: Double = (taraIndex == 0 || taraIndex == 3 || taraIndex == 6) ? 0 : 3
        let note = "Step \(step) (tara \(taraNumber))"
        return AshtakootaItem(id: "tara", name: "Tara", points: points, maxPoints: 3, note: note)
    }

    private static func yoniKoota(groom: MatchProfile, bride: MatchProfile) -> AshtakootaItem {
        guard let groomYoni = yoniMap[groom.moonNakshatra],
              let brideYoni = yoniMap[bride.moonNakshatra] else {
            return AshtakootaItem(id: "yoni", name: "Yoni", points: 0, maxPoints: 4, note: "Yoni: unknown nakshatra")
        }
        let points: Double
        let note: String
        if groomYoni.animal == brideYoni.animal {
            points = 4
            note = "Same yoni (\(groomYoni.animal))"
        } else if isYoniEnemy(groomYoni.animal, brideYoni.animal) {
            points = 0
            note = "Enemy yoni (\(groomYoni.animal) vs \(brideYoni.animal))"
        } else {
            points = 2
            note = "Neutral yoni (\(groomYoni.animal) vs \(brideYoni.animal))"
        }
        return AshtakootaItem(
            id: "yoni",
            name: "Yoni",
            points: points,
            maxPoints: 4,
            note: "\(note); \(groomYoni.sex) vs \(brideYoni.sex)"
        )
    }

    private static func grahaMaitriKoota(groom: MatchProfile, bride: MatchProfile) -> AshtakootaItem {
        guard let groomLord = signLordMap[groom.moonSign],
              let brideLord = signLordMap[bride.moonSign] else {
            return AshtakootaItem(id: "maitri", name: "Graha maitri", points: 0, maxPoints: 5, note: "Graha maitri: unknown Moon sign")
        }
        let groomRelation = friendship(from: groomLord, to: brideLord)
        let brideRelation = friendship(from: brideLord, to: groomLord)
        let points: Double
        switch (groomRelation, brideRelation) {
        case (.same, _), (_, .same):
            points = 5
        case (.friend, .friend):
            points = 5
        case (.friend, .neutral), (.neutral, .friend):
            points = 4
        case (.neutral, .neutral):
            points = 3
        case (.enemy, .enemy):
            points = 0
        default:
            points = 1
        }
        let note = "\(groomLord) (\(groomRelation.rawValue)) / \(brideLord) (\(brideRelation.rawValue))"
        return AshtakootaItem(id: "maitri", name: "Graha maitri", points: points, maxPoints: 5, note: note)
    }

    private static func ganaKoota(groom: MatchProfile, bride: MatchProfile) -> AshtakootaItem {
        guard let groomGana = ganaMap[groom.moonNakshatra],
              let brideGana = ganaMap[bride.moonNakshatra] else {
            return AshtakootaItem(id: "gana", name: "Gana", points: 0, maxPoints: 6, note: "Gana: unknown nakshatra")
        }
        let points: Double
        if groomGana == brideGana {
            points = 6
        } else if Set([groomGana, brideGana]) == Set(["Deva", "Manushya"]) {
            points = 5
        } else if Set([groomGana, brideGana]) == Set(["Deva", "Rakshasa"]) {
            points = 1
        } else {
            points = 0
        }
        let note = "\(groomGana) + \(brideGana)"
        return AshtakootaItem(id: "gana", name: "Gana", points: points, maxPoints: 6, note: note)
    }

    private static func bhakootKoota(groom: MatchProfile, bride: MatchProfile) -> AshtakootaItem {
        guard let aIndex = signOrder.firstIndex(of: groom.moonSign),
              let bIndex = signOrder.firstIndex(of: bride.moonSign) else {
            return AshtakootaItem(id: "bhakoot", name: "Bhakoot", points: 0, maxPoints: 7, note: "Bhakoot: unknown Moon sign")
        }
        let diff = abs(aIndex - bIndex)
        let minDiff = min(diff, 12 - diff)
        let isDosha = (minDiff == 1 || minDiff == 4)
        let points: Double = isDosha ? 0 : 7
        let note = isDosha ? "Dosha (2/12 or 5/9)" : "No dosha"
        return AshtakootaItem(id: "bhakoot", name: "Bhakoot", points: points, maxPoints: 7, note: note)
    }

    private static func nadiKoota(groom: MatchProfile, bride: MatchProfile) -> AshtakootaItem {
        guard let groomNadi = nadi(for: groom.moonNakshatra),
              let brideNadi = nadi(for: bride.moonNakshatra) else {
            return AshtakootaItem(id: "nadi", name: "Nadi", points: 0, maxPoints: 8, note: "Nadi: unknown nakshatra")
        }
        let points: Double = groomNadi == brideNadi ? 0 : 8
        let note = "\(groomNadi) vs \(brideNadi)"
        return AshtakootaItem(id: "nadi", name: "Nadi", points: points, maxPoints: 8, note: note)
    }

    private static func varna(for sign: String) -> Varna? {
        let elementMap: [String: String] = [
            "Aries": "Fire", "Leo": "Fire", "Sagittarius": "Fire",
            "Taurus": "Earth", "Virgo": "Earth", "Capricorn": "Earth",
            "Gemini": "Air", "Libra": "Air", "Aquarius": "Air",
            "Cancer": "Water", "Scorpio": "Water", "Pisces": "Water"
        ]
        guard let element = elementMap[sign] else { return nil }
        switch element {
        case "Water": return .brahmin
        case "Fire": return .kshatriya
        case "Earth": return .vaishya
        case "Air": return .shudra
        default: return nil
        }
    }

    private static func vashyaCategory(for sign: String) -> VashyaCategory? {
        switch sign {
        case "Aries", "Taurus", "Leo", "Capricorn":
            return .chatushpada
        case "Gemini", "Virgo", "Libra", "Aquarius":
            return .manava
        case "Cancer", "Pisces":
            return .jalachara
        case "Scorpio":
            return .keeta
        case "Sagittarius":
            return .vanachara
        default:
            return nil
        }
    }

    private static func vashyaPoints(male: VashyaCategory, female: VashyaCategory) -> Double {
        if male == female {
            return 2
        }
        if male == .keeta && female != .keeta {
            return 0
        }
        if female == .keeta && male != .chatushpada {
            return 0
        }
        return 1
    }

    private static let yoniMap: [String: YoniInfo] = [
        "Ashwini": YoniInfo(animal: "Horse", sex: "M"),
        "Bharani": YoniInfo(animal: "Elephant", sex: "F"),
        "Krittika": YoniInfo(animal: "Sheep", sex: "F"),
        "Rohini": YoniInfo(animal: "Serpent", sex: "M"),
        "Mrigashira": YoniInfo(animal: "Serpent", sex: "F"),
        "Ardra": YoniInfo(animal: "Dog", sex: "F"),
        "Punarvasu": YoniInfo(animal: "Cat", sex: "F"),
        "Pushya": YoniInfo(animal: "Sheep", sex: "M"),
        "Ashlesha": YoniInfo(animal: "Cat", sex: "M"),
        "Magha": YoniInfo(animal: "Rat", sex: "M"),
        "Purva Phalguni": YoniInfo(animal: "Rat", sex: "F"),
        "Uttara Phalguni": YoniInfo(animal: "Cow", sex: "F"),
        "Hasta": YoniInfo(animal: "Buffalo", sex: "F"),
        "Chitra": YoniInfo(animal: "Tiger", sex: "F"),
        "Swati": YoniInfo(animal: "Buffalo", sex: "M"),
        "Vishakha": YoniInfo(animal: "Tiger", sex: "M"),
        "Anuradha": YoniInfo(animal: "Deer", sex: "F"),
        "Jyeshtha": YoniInfo(animal: "Deer", sex: "M"),
        "Mula": YoniInfo(animal: "Dog", sex: "M"),
        "Purva Ashadha": YoniInfo(animal: "Monkey", sex: "M"),
        "Uttara Ashadha": YoniInfo(animal: "Mongoose", sex: "M"),
        "Shravana": YoniInfo(animal: "Monkey", sex: "F"),
        "Dhanishta": YoniInfo(animal: "Lion", sex: "F"),
        "Shatabhisha": YoniInfo(animal: "Horse", sex: "F"),
        "Purva Bhadrapada": YoniInfo(animal: "Lion", sex: "M"),
        "Uttara Bhadrapada": YoniInfo(animal: "Cow", sex: "M"),
        "Revati": YoniInfo(animal: "Elephant", sex: "M")
    ]

    private static let yoniEnemyPairs: [(String, String)] = [
        ("Horse", "Buffalo"),
        ("Elephant", "Lion"),
        ("Sheep", "Monkey"),
        ("Serpent", "Mongoose"),
        ("Dog", "Deer"),
        ("Cat", "Rat"),
        ("Cow", "Tiger")
    ]

    private static func isYoniEnemy(_ a: String, _ b: String) -> Bool {
        yoniEnemyPairs.contains { ($0.0 == a && $0.1 == b) || ($0.0 == b && $0.1 == a) }
    }

    private static let signLordMap: [String: String] = [
        "Aries": "Mars",
        "Taurus": "Venus",
        "Gemini": "Mercury",
        "Cancer": "Moon",
        "Leo": "Sun",
        "Virgo": "Mercury",
        "Libra": "Venus",
        "Scorpio": "Mars",
        "Sagittarius": "Jupiter",
        "Capricorn": "Saturn",
        "Aquarius": "Saturn",
        "Pisces": "Jupiter"
    ]

    private static let planetFriends: [String: Set<String>] = [
        "Sun": ["Moon", "Mars", "Jupiter"],
        "Moon": ["Sun", "Mercury"],
        "Mars": ["Sun", "Moon", "Jupiter"],
        "Mercury": ["Sun", "Venus"],
        "Jupiter": ["Sun", "Moon", "Mars"],
        "Venus": ["Mercury", "Saturn"],
        "Saturn": ["Mercury", "Venus"]
    ]

    private static let planetEnemies: [String: Set<String>] = [
        "Sun": ["Venus", "Saturn"],
        "Moon": [],
        "Mars": ["Mercury"],
        "Mercury": ["Moon"],
        "Jupiter": ["Venus", "Mercury"],
        "Venus": ["Sun", "Moon"],
        "Saturn": ["Sun", "Moon"]
    ]

    private static func friendship(from planet: String, to other: String) -> Friendship {
        if planet == other {
            return .same
        }
        if planetFriends[planet]?.contains(other) == true {
            return .friend
        }
        if planetEnemies[planet]?.contains(other) == true {
            return .enemy
        }
        return .neutral
    }

    private static let ganaMap: [String: String] = [
        "Ashwini": "Deva",
        "Bharani": "Manushya",
        "Krittika": "Rakshasa",
        "Rohini": "Manushya",
        "Mrigashira": "Deva",
        "Ardra": "Manushya",
        "Punarvasu": "Deva",
        "Pushya": "Deva",
        "Ashlesha": "Rakshasa",
        "Magha": "Rakshasa",
        "Purva Phalguni": "Manushya",
        "Uttara Phalguni": "Manushya",
        "Hasta": "Deva",
        "Chitra": "Rakshasa",
        "Swati": "Deva",
        "Vishakha": "Rakshasa",
        "Anuradha": "Deva",
        "Jyeshtha": "Rakshasa",
        "Mula": "Rakshasa",
        "Purva Ashadha": "Manushya",
        "Uttara Ashadha": "Manushya",
        "Shravana": "Deva",
        "Dhanishta": "Rakshasa",
        "Shatabhisha": "Rakshasa",
        "Purva Bhadrapada": "Manushya",
        "Uttara Bhadrapada": "Manushya",
        "Revati": "Deva"
    ]

    private static func nadi(for nakshatra: String) -> String? {
        guard let index = nakshatraOrder.firstIndex(of: nakshatra) else { return nil }
        // Nadi repeats every 3 nakshatras starting from Ashwini.
        switch index % 3 {
        case 0: return "Aadi"
        case 1: return "Madhya"
        default: return "Antya"
        }
    }
}
