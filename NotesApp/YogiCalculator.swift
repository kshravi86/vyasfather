import Foundation

struct YogiCalculator {
    private static let NAK_LEN = 360.0 / 27.0 // 13.333333°
    private static let YOGI_OFFSET = 93.0 + 20.0 / 60.0 // 93.333333°
    private static let AVAYOGI_OFFSET = 186.0 + 40.0 / 60.0 // 186.666667°

    private static let vimOrder = [
        "Ketu", "Venus", "Sun", "Moon", "Mars",
        "Rahu", "Jupiter", "Saturn", "Mercury"
    ]

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
        "Aries","Taurus","Gemini","Cancer","Leo","Virgo","Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"
    ]

    private static let nakshatraNames: [String] = [
        "Ashwini","Bharani","Krittika","Rohini","Mrigashira","Ardra","Punarvasu","Pushya","Ashlesha",
        "Magha","Purva Phalguni","Uttara Phalguni","Hasta","Chitra","Swati","Vishakha","Anuradha",
        "Jyeshtha","Mula","Purva Ashadha","Uttara Ashadha","Shravana","Dhanishta","Shatabhisha","Purva Bhadrapada","Uttara Bhadrapada","Revati"
    ]

    private static func normalize(_ degrees: Double) -> Double {
        var result = degrees.truncatingRemainder(dividingBy: 360.0)
        if result < 0 { result += 360.0 }
        return result
    }

    private static func nakshatraIndex(from degrees: Double) -> Int {
        let normalized = normalize(degrees)
        let index = Int(floor(normalized / NAK_LEN))
        return min(max(index, 0), 26)
    }

    private static func nakshatraLord(from degrees: Double) -> String {
        let index = nakshatraIndex(from: degrees)
        return vimOrder[index % vimOrder.count]
    }

    private static func signIndex(from degrees: Double) -> Int {
        let normalized = normalize(degrees)
        let index = Int(normalized / 30.0)
        return min(max(index, 0), 11)
    }

    private static func signLord(from degrees: Double) -> String {
        let index = signIndex(from: degrees)
        return signLords[index]
    }

    private static func signName(from degrees: Double) -> String {
        let index = signIndex(from: degrees)
        return signNames[index]
    }

    private static func nakshatraNameAndPada(from degrees: Double) -> (String, Int) {
        let normalized = normalize(degrees)
        let idx = Int(floor(normalized / NAK_LEN))
        let safeIdx = min(max(idx, 0), 26)
        let start = Double(safeIdx) * NAK_LEN
        let rem = normalized - start
        let pada = Int(floor(rem / (NAK_LEN / 4.0))) + 1 // 1..4
        let name = nakshatraNames[safeIdx]
        return (name, max(1, min(4, pada)))
    }

    static func computeYogiPoint(sunLongitude: Double, moonLongitude: Double) -> Double {
        return normalize(sunLongitude + moonLongitude + YOGI_OFFSET)
    }

    static func computeAvayogiPoint(yogiPoint: Double) -> Double {
        return normalize(yogiPoint + AVAYOGI_OFFSET)
    }

    static func avayogiBy6th(yogiLord: String) -> String? {
        guard let index = vimOrder.firstIndex(where: { $0.caseInsensitiveCompare(yogiLord) == .orderedSame }) else {
            return nil
        }
        let avayogiIndex = (index + 5) % vimOrder.count
        return vimOrder[avayogiIndex]
    }

    struct YogiResult {
        let yogiPoint: Double
        let yogiPlanet: String
        let yogiNakshatra: String
        let yogiPada: Int
        let yogiSign: String
        let sahayogi: String
        let avayogiPoint: Double
        let avayogiPlanet: String
        let avayogiNakshatra: String
        let avayogiPada: Int
        let avayogiSign: String
        let avayogiVia6th: String?

        func formatDegrees(_ degrees: Double) -> String {
            let normalized = YogiCalculator.normalize(degrees)
            let deg = Int(normalized)
            let min = Int((normalized - Double(deg)) * 60.0 + 0.5)
            return String(format: "%03d° %02d'", deg, min)
        }
    }

    static func calculate(sunLongitude: Double, moonLongitude: Double) -> YogiResult {
        let yogiPoint = computeYogiPoint(sunLongitude: sunLongitude, moonLongitude: moonLongitude)
        let yogiPlanet = nakshatraLord(from: yogiPoint)
        let (yogiNak, yogiPada) = nakshatraNameAndPada(from: yogiPoint)
        let yogiSign = signName(from: yogiPoint)
        let sahayogi = signLord(from: yogiPoint)
        let avayogiPoint = computeAvayogiPoint(yogiPoint: yogiPoint)
        let avayogiPlanet = nakshatraLord(from: avayogiPoint)
        let (avaNak, avaPada) = nakshatraNameAndPada(from: avayogiPoint)
        let avayogiSign = signName(from: avayogiPoint)
        let avayogiVia6th = avayogiBy6th(yogiLord: yogiPlanet)

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
