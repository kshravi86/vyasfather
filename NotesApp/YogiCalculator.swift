import Foundation

/// Calculates the Yogi Point, Avayogi Point, and their associated planets
/// from a birth chart's sidereal Sun and Moon longitudes.
///
/// **System overview**
///
/// - **Yogi Point** = (Sun + Moon + 93°20') mod 360°
///   The nakshatra lord of this point is the *Yogi Planet* — a planet that brings
///   fortune and support throughout the native's life.
///
/// - **Avayogi Point** = (Yogi Point + 186°40') mod 360°
///   Exactly opposite-plus-half-a-nakshatra from the Yogi Point. Its nakshatra
///   lord is the *Avayogi* — a planet that may obstruct or delay results.
///
/// - **Sahayogi** (helper) = the sign lord of the Yogi Point's sign.
///   Acts as a supporting planet that facilitates the Yogi Planet's benefits.
///
/// The constants 93°20' (= 93 + 20/60) and 186°40' (= 186 + 40/60) are traditional
/// and correspond to 7 nakshatras and 14 nakshatras respectively on the 13°20' grid.
struct YogiCalculator {

    // MARK: - Constants

    /// Nakshatra arc length in degrees (360 / 27 ≈ 13.333°).
    private static let NAK_LEN = 360.0 / 27.0

    /// Traditional offset added to (Sun + Moon) to arrive at the Yogi Point.
    private static let YOGI_OFFSET = 93.0 + 20.0 / 60.0    // 93°20' = 7 nakshatras

    /// Additional offset from the Yogi Point to the Avayogi Point.
    private static let AVAYOGI_OFFSET = 186.0 + 40.0 / 60.0 // 186°40' = 14 nakshatras

    // MARK: - Lookup tables

    /// Vimshottari planet order used to map nakshatra index → ruling planet.
    /// Nakshatra i is ruled by vimOrder[i % 9].
    private static let vimOrder = [
        "Ketu", "Venus", "Sun", "Moon", "Mars",
        "Rahu", "Jupiter", "Saturn", "Mercury"
    ]

    /// Sign lord for each of the 12 zodiac signs (index 0 = Aries).
    private static let signLords: [String] = [
        "Mars",    // Aries
        "Venus",   // Taurus
        "Mercury", // Gemini
        "Moon",    // Cancer
        "Sun",     // Leo
        "Mercury", // Virgo
        "Venus",   // Libra
        "Mars",    // Scorpio
        "Jupiter", // Sagittarius
        "Saturn",  // Capricorn
        "Saturn",  // Aquarius
        "Jupiter"  // Pisces
    ]

    private static let signNames: [String] = [
        "Aries","Taurus","Gemini","Cancer","Leo","Virgo",
        "Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"
    ]

    private static let nakshatraNames: [String] = [
        "Ashwini","Bharani","Krittika","Rohini","Mrigashira","Ardra","Punarvasu","Pushya","Ashlesha",
        "Magha","Purva Phalguni","Uttara Phalguni","Hasta","Chitra","Swati","Vishakha","Anuradha",
        "Jyeshtha","Mula","Purva Ashadha","Uttara Ashadha","Shravana","Dhanishta","Shatabhisha",
        "Purva Bhadrapada","Uttara Bhadrapada","Revati"
    ]

    // MARK: - Normalisation helpers

    private static func normalize(_ degrees: Double) -> Double {
        var result = degrees.truncatingRemainder(dividingBy: 360.0)
        if result < 0 { result += 360.0 }
        return result
    }

    /// 0-based nakshatra index (0..26) for a given ecliptic longitude.
    private static func nakshatraIndex(from degrees: Double) -> Int {
        let normalized = normalize(degrees)
        let index = Int(floor(normalized / NAK_LEN))
        return min(max(index, 0), 26)
    }

    /// Vimshottari planet ruling the nakshatra at `degrees`.
    private static func nakshatraLord(from degrees: Double) -> String {
        let index = nakshatraIndex(from: degrees)
        return vimOrder[index % vimOrder.count]
    }

    /// 0-based sign index (0..11) for a given ecliptic longitude.
    private static func signIndex(from degrees: Double) -> Int {
        let normalized = normalize(degrees)
        let index = Int(normalized / 30.0)
        return min(max(index, 0), 11)
    }

    /// Traditional sign lord (dispositor) for the sign at `degrees`.
    private static func signLord(from degrees: Double) -> String {
        let index = signIndex(from: degrees)
        return signLords[index]
    }

    private static func signName(from degrees: Double) -> String {
        let index = signIndex(from: degrees)
        return signNames[index]
    }

    /// Returns the nakshatra name and pada (1–4) for a given longitude.
    private static func nakshatraNameAndPada(from degrees: Double) -> (String, Int) {
        let normalized = normalize(degrees)
        let idx = Int(floor(normalized / NAK_LEN))
        let safeIdx = min(max(idx, 0), 26)
        let start = Double(safeIdx) * NAK_LEN
        let rem = normalized - start
        let pada = Int(floor(rem / (NAK_LEN / 4.0))) + 1  // 1..4
        let name = nakshatraNames[safeIdx]
        return (name, max(1, min(4, pada)))
    }

    // MARK: - Core formulas

    /// Computes the Yogi Point longitude from sidereal Sun and Moon longitudes.
    static func computeYogiPoint(sunLongitude: Double, moonLongitude: Double) -> Double {
        return normalize(sunLongitude + moonLongitude + YOGI_OFFSET)
    }

    /// Computes the Avayogi Point as 186°40' ahead of the Yogi Point.
    static func computeAvayogiPoint(yogiPoint: Double) -> Double {
        return normalize(yogiPoint + AVAYOGI_OFFSET)
    }

    /// Alternative Avayogi derivation: the 6th planet in the Vimshottari sequence
    /// counting forward from the Yogi Planet. This is the classical textual method
    /// and serves as a cross-check against the longitude-based method.
    static func avayogiBy6th(yogiLord: String) -> String? {
        guard let index = vimOrder.firstIndex(where: { $0.caseInsensitiveCompare(yogiLord) == .orderedSame }) else {
            return nil
        }
        // The 6th planet after the Yogi Lord (1-indexed, so offset by 5).
        let avayogiIndex = (index + 5) % vimOrder.count
        return vimOrder[avayogiIndex]
    }

    // MARK: - Result model

    /// All computed Yogi/Avayogi data for display.
    struct YogiResult {
        let yogiPoint: Double          // Ecliptic longitude of the Yogi Point
        let yogiPlanet: String         // Nakshatra lord of the Yogi Point
        let yogiNakshatra: String      // Nakshatra name
        let yogiPada: Int              // Pada within the nakshatra (1–4)
        let yogiSign: String           // Zodiac sign of the Yogi Point
        let sahayogi: String           // Sign lord of the Yogi Point's sign (helper planet)
        let avayogiPoint: Double       // Ecliptic longitude of the Avayogi Point
        let avayogiPlanet: String      // Nakshatra lord of the Avayogi Point
        let avayogiNakshatra: String
        let avayogiPada: Int
        let avayogiSign: String
        let avayogiVia6th: String?     // Cross-check Avayogi using the 6th-planet method

        /// Formats an ecliptic longitude as "DDD° MM'" for UI display.
        func formatDegrees(_ degrees: Double) -> String {
            let normalized = YogiCalculator.normalize(degrees)
            let deg = Int(normalized)
            let min = Int((normalized - Double(deg)) * 60.0 + 0.5)
            return String(format: "%03d° %02d'", deg, min)
        }
    }

    // MARK: - Main entry point

    /// Derives the complete Yogi/Avayogi result from sidereal Sun and Moon longitudes.
    static func calculate(sunLongitude: Double, moonLongitude: Double) -> YogiResult {
        let yogiPoint      = computeYogiPoint(sunLongitude: sunLongitude, moonLongitude: moonLongitude)
        let yogiPlanet     = nakshatraLord(from: yogiPoint)
        let (yogiNak, yogiPada) = nakshatraNameAndPada(from: yogiPoint)
        let yogiSign       = signName(from: yogiPoint)
        let sahayogi       = signLord(from: yogiPoint)
        let avayogiPoint   = computeAvayogiPoint(yogiPoint: yogiPoint)
        let avayogiPlanet  = nakshatraLord(from: avayogiPoint)
        let (avaNak, avaPada) = nakshatraNameAndPada(from: avayogiPoint)
        let avayogiSign    = signName(from: avayogiPoint)
        let avayogiVia6th  = avayogiBy6th(yogiLord: yogiPlanet)

        return YogiResult(
            yogiPoint: yogiPoint,
            yogiPlanet: yogiPlanet,
            yogiNakshatra: yogiNak,
            yogiPada: yogiPada,
            yogiSign: yogiSign,
            sahayogi: sahayogi,
            avayogiPoint: avayogiPoint,
            avayogiPlanet: avayogiPlanet,
            avayogiNakshatra: avaNak,
            avayogiPada: avaPada,
            avayogiSign: avayogiSign,
            avayogiVia6th: avayogiVia6th
        )
    }
}
