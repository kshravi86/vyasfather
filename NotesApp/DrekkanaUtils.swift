import Foundation

enum Modality {
    case movable
    case fixed
    case dual
}

enum ZodiacSign: Int, CaseIterable {
    case aries = 0, taurus, gemini, cancer, leo, virgo, libra, scorpio, sagittarius, capricorn, aquarius, pisces

    var displayName: String {
        switch self {
        case .aries: return "Aries"
        case .taurus: return "Taurus"
        case .gemini: return "Gemini"
        case .cancer: return "Cancer"
        case .leo: return "Leo"
        case .virgo: return "Virgo"
        case .libra: return "Libra"
        case .scorpio: return "Scorpio"
        case .sagittarius: return "Sagittarius"
        case .capricorn: return "Capricorn"
        case .aquarius: return "Aquarius"
        case .pisces: return "Pisces"
        }
    }

    static func from(name: String) -> ZodiacSign? {
        let lower = name.lowercased()
        switch lower {
        case "aries": return .aries
        case "taurus": return .taurus
        case "gemini": return .gemini
        case "cancer": return .cancer
        case "leo": return .leo
        case "virgo": return .virgo
        case "libra": return .libra
        case "scorpio": return .scorpio
        case "sagittarius": return .sagittarius
        case "capricorn": return .capricorn
        case "aquarius": return .aquarius
        case "pisces": return .pisces
        default: return nil
        }
    }
}

struct DrekkanaUtils {
    private static func modality(of sign: ZodiacSign) -> Modality {
        switch sign {
        case .aries, .cancer, .libra, .capricorn: return .movable
        case .taurus, .leo, .scorpio, .aquarius: return .fixed
        case .gemini, .virgo, .sagittarius, .pisces: return .dual
        }
    }

    private static func normalizedDegree(_ deg: Double) -> Double {
        var d = deg.truncatingRemainder(dividingBy: 360.0)
        if d < 0 { d += 360.0 }
        return d
    }

    private static func degreeInSign(_ absoluteDegree: Double) -> Double {
        let normalized = normalizedDegree(absoluteDegree)
        var inSign = normalized.truncatingRemainder(dividingBy: 30.0)
        if inSign < 0 { inSign += 30.0 }
        return inSign
    }

    static func isUttamaDrekkana(sign: ZodiacSign, absoluteDegree: Double) -> Bool {
        // Meena 2 Nadi rule from uknowwhat.txt:
        // Movable: 0°00'–10°00' (inclusive of 10°00')
        // Fixed:   10°01'–20°00' (i.e., >10°00' and <=20°00')
        // Dual:    20°01'–30°00' (i.e., >20°00' and <30°00')
        let d = degreeInSign(absoluteDegree)
        switch modality(of: sign) {
        case .movable:
            return d >= 0.0 && d <= 10.0
        case .fixed:
            return d > 10.0 && d <= 20.0
        case .dual:
            return d > 20.0 && d < 30.0
        }
    }

    static func rangeDescription(for sign: ZodiacSign) -> String {
        switch modality(of: sign) {
        case .movable: return "0°00–10°00"
        case .fixed: return "10°01–20°00"
        case .dual: return "20°01–30°00"
        }
    }
}
