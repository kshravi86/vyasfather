import Foundation

/// Aggregated output from a single Panchanga computation.
/// All five limbs (Pancha = five, Anga = limb) are included plus their ruling planets.
struct PanchangaResultModel {
    let tithi: String          // Lunar day with paksha prefix, e.g. "Shukla Panchami"
    let tithiGroup: String     // One of Nanda/Bhadra/Jaya/Rikta/Poorna (quality group)
    let vara: String           // Weekday in Sanskrit, e.g. "Guruvara" (Thursday)
    let nakshatra: String      // Moon's nakshatra + pada, e.g. "Rohini • Pada 2"
    let yoga: String           // Luni-solar yoga name, e.g. "Siddhi"
    let karana: String         // Half-tithi name, e.g. "Bava"
    let yogaLord: String       // Ruling planet of the current yoga
    let karanaLord: String     // Ruling planet of the current karana
}

/// Stateless calculator for the five classical Panchanga limbs.
///
/// **Formula overview**
///
/// | Limb     | Formula                                   | Cycle      |
/// |----------|-------------------------------------------|------------|
/// | Tithi    | floor((Moon − Sun) / 12°)                 | 30 tithis  |
/// | Yoga     | floor((Moon + Sun) / 13.333°)             | 27 yogas   |
/// | Karana   | floor((Moon − Sun) / 6°) + 1              | ~60 halves |
/// | Vara     | Gregorian weekday mapped to Sanskrit name | 7 days     |
/// | Nakshatra| Moon's nakshatra index × pada             | 27 × 4     |
enum PanchangaCalcIOS {

    /// Wraps a degree value into [0, 360) using modular arithmetic.
    private static func normalize(_ deg: Double) -> Double {
        var x = deg.truncatingRemainder(dividingBy: 360.0)
        if x < 0 { x += 360.0 }
        return x
    }

    // MARK: - Lookup tables

    /// 30 tithi names for Shukla (waxing, 1–15) and Krishna (waning, 16–30) pakshas.
    /// Index 14 = Purnima (full moon); index 29 = Amavasya (new moon).
    private static let tithiNames: [String] = [
        "Pratipada","Dvitiya","Tritiya","Chaturthi","Panchami",
        "Shashthi","Saptami","Ashtami","Navami","Dashami",
        "Ekadashi","Dvadashi","Trayodashi","Chaturdashi","Purnima",
        "Pratipada","Dvitiya","Tritiya","Chaturthi","Panchami",
        "Shashthi","Saptami","Ashtami","Navami","Dashami",
        "Ekadashi","Dvadashi","Trayodashi","Chaturdashi","Amavasya"
    ]

    /// 27 luni-solar yoga names in the standard sequence starting from Vishkambha.
    private static let yogaNames: [String] = [
        "Vishkambha","Priti","Ayushman","Saubhagya","Shobhana",
        "Atiganda","Sukarma","Dhriti","Shoola","Ganda",
        "Vriddhi","Dhruva","Vyaghata","Harshana","Vajra",
        "Siddhi","Vyatipata","Variyan","Parigha","Shiva",
        "Siddha","Sadhya","Shubha","Shukla","Brahma",
        "Indra","Vaidhriti"
    ]

    /// The 7 movable (chara) karanas that repeat in a fixed cycle through the lunar month.
    /// Preceded by 1 fixed karana (Kimstughna) and followed by 3 fixed ones
    /// (Shakuni, Chatushpada, Naga).
    private static let karanaMovable: [String] = ["Bava","Balava","Kaulava","Taitila","Gara","Vanija","Vishti"]

    // MARK: - Tithi

    /// Returns the full tithi name including paksha (e.g. "Shukla Panchami").
    ///
    /// Tithi index = floor(elongation / 12°), where elongation = Moon − Sun in [0, 360).
    /// Indices 0–14 belong to Shukla Paksha (waxing); 15–29 to Krishna Paksha (waning).
    static func tithiName(moon: Double, sun: Double) -> String {
        let diff = normalize(moon - sun)
        let idx = Int(floor(diff / 12.0)).clamped(to: 0...29)
        let paksha = (idx < 15) ? "Shukla" : "Krishna"
        return "\(paksha) \(tithiNames[idx])"
    }

    // MARK: - Yoga

    /// Returns the luni-solar yoga name for the given Sun and Moon longitudes.
    ///
    /// Yoga index = floor((Moon + Sun) / 13.333°), where 13.333° = 360° / 27.
    /// The yoga advances one step for every 13°20' of combined Sun+Moon motion.
    static func yogaName(moon: Double, sun: Double) -> String {
        let sum = normalize(moon + sun)
        let idx = Int(floor(sum / (360.0 / 27.0))).clamped(to: 0...26)
        return yogaNames[idx]
    }

    // MARK: - Karana

    /// Returns the karana name for the given Sun and Moon longitudes.
    ///
    /// A karana is half a tithi (6° of elongation). The sequence within a lunar month is:
    ///  - Half 1: Kimstughna (fixed, occurs once at the very start of Shukla Paksha)
    ///  - Halves 2–57: the 7 movable karanas cycling repeatedly
    ///  - Half 58: Shakuni (fixed)
    ///  - Half 59: Chatushpada (fixed)
    ///  - Half 60: Naga (fixed, ends Amavasya)
    static func karanaName(moon: Double, sun: Double) -> String {
        let diff = normalize(moon - sun)
        let halfIdx = Int(floor(diff / 6.0)) + 1   // 1-based, range 1..60
        switch halfIdx {
        case 1:      return "Kimstughna"
        case 2...57: return karanaMovable[(halfIdx - 2) % 7]
        case 58:     return "Shakuni"
        case 59:     return "Chatushpada"
        case 60:     return "Naga"
        default:     return ""
        }
    }

    // MARK: - Tithi group

    /// Returns the quality group (Nanda/Bhadra/Jaya/Rikta/Poorna) for a tithi.
    ///
    /// Tithis 1,6,11 (and their Krishna equivalents) = Nanda; 2,7,12 = Bhadra; etc.
    /// This is derived from (inPaksha + 1) mod 5, where inPaksha = tithi index mod 15.
    static func tithiGroupName(moon: Double, sun: Double) -> String {
        let diff = normalize(moon - sun)
        let idx = Int(floor(diff / 12.0)).clamped(to: 0...29)
        let inPaksha = idx % 15
        switch (inPaksha + 1) % 5 {
        case 1: return "Nanda"
        case 2: return "Bhadra"
        case 3: return "Jaya"
        case 4: return "Rikta"
        default: return "Poorna"
        }
    }

    // MARK: - Vara

    /// Returns the Sanskrit weekday name for a given date in the supplied timezone.
    /// The Gregorian calendar weekday (1 = Sunday) maps to the traditional Vedic Vara.
    static func varaName(for date: Date, timeZone: TimeZone) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let wd = cal.component(.weekday, from: date)
        // Gregorian weekday: 1=Sunday, 2=Monday, … 7=Saturday
        switch wd {
        case 1: return "Ravivara"   // Sunday  → Ravi (Sun)
        case 2: return "Somavara"   // Monday  → Soma (Moon)
        case 3: return "Mangalavara"// Tuesday → Mangala (Mars)
        case 4: return "Budhavara"  // Wednesday→ Budha (Mercury)
        case 5: return "Guruvara"   // Thursday→ Guru (Jupiter)
        case 6: return "Shukravara" // Friday  → Shukra (Venus)
        default: return "Shanivara" // Saturday→ Shani (Saturn)
        }
    }

    // MARK: - Full Panchanga

    /// Computes all five Panchanga limbs from a set of planetary positions.
    ///
    /// Requires at least Sun and Moon to be present in `planetPositions`.
    /// Falls back to 0° longitude if either planet is missing.
    static func compute(planetPositions: [PlanetPosition], dateTime: Date, timeZone: TimeZone) -> PanchangaResultModel {
        let sun  = planetPositions.first { $0.name == "Sun"  }?.longitude ?? 0.0
        let moon = planetPositions.first { $0.name == "Moon" }?.longitude ?? 0.0
        let tithi   = tithiName(moon: moon, sun: sun)
        let yoga    = yogaName(moon: moon, sun: sun)
        let karana  = karanaName(moon: moon, sun: sun)
        let vara    = varaName(for: dateTime, timeZone: timeZone)
        // Nakshatra string includes pada for display convenience.
        let nak: String = {
            if let m = planetPositions.first(where: { $0.name == "Moon" }) {
                return "\(m.nakshatra) • Pada \(m.pada)"
            }
            return "—"
        }()
        return PanchangaResultModel(
            tithi: tithi,
            tithiGroup: tithiGroupName(moon: moon, sun: sun),
            vara: vara,
            nakshatra: nak,
            yoga: yoga,
            karana: karana,
            yogaLord: yogaLordOf(yoga),
            karanaLord: karanaLordOf(karana)
        )
    }

    // MARK: - Yoga and Karana lords

    private static let weekdayPlanets = ["Sun","Moon","Mars","Mercury","Jupiter","Venus","Saturn"]

    /// Returns the ruling planet for a given yoga name.
    /// Mapping sourced from classical yoga texts (checkyogas.txt reference).
    static func yogaLordOf(_ yoga: String) -> String {
        let map: [String: String] = [
            "Vishkambha": "Saturn",  "Priti": "Mercury",    "Ayushman": "Ketu",
            "Saubhagya":  "Venus",   "Shobhana": "Sun",     "Atiganda": "Moon",
            "Sukarma":    "Mars",    "Dhriti": "Rahu",      "Shoola": "Jupiter",
            "Ganda":      "Saturn",  "Vriddhi": "Mercury",  "Dhruva": "Ketu",
            "Vyaghata":   "Venus",   "Harshana": "Sun",     "Vajra": "Moon",
            "Siddhi":     "Mars",    "Vyatipata": "Rahu",   "Variyan": "Jupiter",
            "Parigha":    "Saturn",  "Shiva": "Mercury",    "Siddha": "Ketu",
            "Sadhya":     "Venus",   "Shubha": "Sun",       "Shukla": "Moon",
            "Brahma":     "Mars",    "Indra": "Rahu",       "Vaidhriti": "Jupiter"
        ]
        return map[yoga] ?? "—"
    }

    /// Returns the ruling planet for a given karana name.
    /// Mapping sourced from classical karana texts (karanas.txt reference).
    static func karanaLordOf(_ karana: String) -> String {
        let map: [String: String] = [
            // Movable karanas (cycle of 7)
            "Bava": "Sun",    "Balava": "Moon",  "Kaulava": "Mars",
            "Taitila": "Mercury", "Gara": "Jupiter", "Vanija": "Venus",
            "Vishti": "Saturn",
            // Fixed karanas
            "Shakuni": "Rahu", "Chatushpada": "Ketu",
            "Naga": "Rahu",    "Kimstughna": "Ketu"
        ]
        return map[karana] ?? "—"
    }
}
