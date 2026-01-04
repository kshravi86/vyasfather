import Foundation
import CoreLocation

struct GhatikaLagnaModel { let longitude: Double; let sign: String }
struct HoraLagnaModel { let longitude: Double; let sign: String; let houseFromAsc: Int; let ishtaHours: Double; let sunrise: Date }
struct InduLagnaModel { let sign: String; let houseFromAsc: Int; let ninthLordFromAsc: String; let ninthLordFromMoon: String; let sumValue: Int; let remainder: Int }

enum SpecialLagnasCalc {
    private static func normalize360(_ x: Double) -> Double { let y = fmod(x, 360.0); return y < 0 ? y + 360.0 : y }

    static func ghatikaLagna(date: Date, tz: TimeZone, coord: CLLocationCoordinate2D, calculator: PlanetaryCalculator) -> GhatikaLagnaModel? {
        guard let sr = SunriseCalcIOS.sunrise(on: date, latitude: coord.latitude, longitude: coord.longitude, timeZone: tz) ?? SunriseCalcIOS.sunrise(on: Date(timeIntervalSince1970: date.timeIntervalSince1970 - 86400), latitude: coord.latitude, longitude: coord.longitude, timeZone: tz) else { return nil }
        // Sun at sunrise
        let sunLon = sunLongitude(at: sr, tz: tz, coord: coord, calculator: calculator)
        // elapsed minutes
        let minutes = max(0.0, date.timeIntervalSince(sr) / 60.0)
        let advance = minutes * 1.25 // 1.25° per minute
        let gl = normalize360(sunLon + advance)
        return GhatikaLagnaModel(longitude: gl, sign: ZodiacSign(rawValue: Int(floor(gl/30.0)) % 12)?.displayName ?? "Aries")
    }

    static func horaLagna(date: Date, tz: TimeZone, coord: CLLocationCoordinate2D, natalAscAbs: Double, calculator: PlanetaryCalculator) -> HoraLagnaModel? {
        guard let sr = SunriseCalcIOS.sunrise(on: date, latitude: coord.latitude, longitude: coord.longitude, timeZone: tz) ?? SunriseCalcIOS.sunrise(on: Date(timeIntervalSince1970: date.timeIntervalSince1970 - 86400), latitude: coord.latitude, longitude: coord.longitude, timeZone: tz) else { return nil }
        let sunLon = sunLongitude(at: sr, tz: tz, coord: coord, calculator: calculator)
        let ishtaHours = max(0.0, date.timeIntervalSince(sr) / 3600.0)
        let movement = ishtaHours * 30.0
        let hl = normalize360(sunLon + movement)
        let sign = ZodiacSign(rawValue: Int(floor(hl/30.0)) % 12)?.displayName ?? "Aries"
        let houseFromAsc = ((normalize360(hl - natalAscAbs) / 30.0).rounded(.down) + 1).truncatingRemainder(dividingBy: 12)
        let hFromAsc = Int(houseFromAsc == 0 ? 12 : houseFromAsc)
        return HoraLagnaModel(longitude: hl, sign: sign, houseFromAsc: hFromAsc, ishtaHours: ishtaHours, sunrise: sr)
    }

    static func horaLagnaJaimini(date: Date, tz: TimeZone, coord: CLLocationCoordinate2D, calculator: PlanetaryCalculator) -> GhatikaLagnaModel? {
        guard let sr = SunriseCalcIOS.sunrise(on: date, latitude: coord.latitude, longitude: coord.longitude, timeZone: tz) ?? SunriseCalcIOS.sunrise(on: Date(timeIntervalSince1970: date.timeIntervalSince1970 - 86400), latitude: coord.latitude, longitude: coord.longitude, timeZone: tz) else { return nil }
        let sunLon = sunLongitude(at: sr, tz: tz, coord: coord, calculator: calculator)
        let seconds = max(0.0, date.timeIntervalSince(sr))
        let hrs = floor(seconds / 3600.0)
        let mins = floor((seconds - hrs*3600.0)/60.0)
        let secs = seconds - hrs*3600.0 - mins*60.0
        let advance = 30.0 * hrs + 0.5 * mins + (0.5/60.0) * secs
        let hl = normalize360(sunLon + advance)
        return GhatikaLagnaModel(longitude: hl, sign: ZodiacSign(rawValue: Int(floor(hl/30.0)) % 12)?.displayName ?? "Aries")
    }

    static func induLagna(planetPositions: [PlanetPosition], ascSignName: String) -> InduLagnaModel? {
        guard let moon = planetPositions.first(where: { $0.name == "Moon" }) else { return nil }
        let ascSign = ZodiacSign.from(name: ascSignName) ?? .aries
        let moonSign = ZodiacSign.from(name: moon.sign) ?? .aries
        let ninthFromAsc = ZodiacSign(rawValue: (ascSign.rawValue + 8) % 12) ?? .sagittarius
        let ninthFromMoon = ZodiacSign(rawValue: (moonSign.rawValue + 8) % 12) ?? .sagittarius
        let lordAsc = signLord(of: ninthFromAsc)
        let lordMoon = signLord(of: ninthFromMoon)
        let sum = kalaValue(of: lordAsc) + kalaValue(of: lordMoon)
        var r = sum % 12
        if r == 0 { r = 12 }
        let induSignIdx = (moonSign.rawValue + (r - 1)) % 12
        let induSign = ZodiacSign(rawValue: induSignIdx)?.displayName ?? "Aries"
        let houseFromAsc = ((induSignIdx - ascSign.rawValue + 12) % 12) + 1
        return InduLagnaModel(sign: induSign, houseFromAsc: houseFromAsc, ninthLordFromAsc: lordAsc, ninthLordFromMoon: lordMoon, sumValue: sum, remainder: r)
    }

    private static func sunLongitude(at date: Date, tz: TimeZone, coord: CLLocationCoordinate2D, calculator: PlanetaryCalculator) -> Double {
        // We can reuse PlanetaryCalculator to get Sun longitude by splitting date/time
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let d = cal.startOfDay(for: date)
        let comp = cal.dateComponents([.hour, .minute, .second], from: date)
        let timeOnly = cal.date(bySettingHour: comp.hour ?? 0, minute: comp.minute ?? 0, second: comp.second ?? 0, of: d) ?? date
        let positions = calculator.compute(date: d, time: timeOnly, coordinate: coord, timeZone: tz)
        return positions.first(where: { $0.name == "Sun" })?.longitude ?? 0.0
    }

    private static func signLord(of sign: ZodiacSign) -> String {
        switch sign {
        case .aries: return "Mars"
        case .taurus: return "Venus"
        case .gemini: return "Mercury"
        case .cancer: return "Moon"
        case .leo: return "Sun"
        case .virgo: return "Mercury"
        case .libra: return "Venus"
        case .scorpio: return "Mars"
        case .sagittarius: return "Jupiter"
        case .capricorn: return "Saturn"
        case .aquarius: return "Saturn"
        case .pisces: return "Jupiter"
        }
    }

    private static func kalaValue(of planet: String) -> Int {
        switch planet.lowercased() {
        case "sun": return 30
        case "moon": return 16
        case "mars": return 6
        case "mercury": return 8
        case "jupiter": return 10
        case "venus": return 12
        case "saturn": return 1
        default: return 0
        }
    }
}

