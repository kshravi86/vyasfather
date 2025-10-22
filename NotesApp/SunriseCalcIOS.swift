import Foundation

enum SunriseCalcIOS {
    // Returns sunrise time (approximate, civil sunrise at -0.833°) in local time zone
    // Algorithm adapted from NOAA Solar Calculator
    static func sunrise(on date: Date, latitude: Double, longitude: Double, timeZone: TimeZone) -> Date? {
        return solarEvent(on: date, latitude: latitude, longitude: longitude, timeZone: timeZone, isSunrise: true)
    }

    static func sunset(on date: Date, latitude: Double, longitude: Double, timeZone: TimeZone) -> Date? {
        return solarEvent(on: date, latitude: latitude, longitude: longitude, timeZone: timeZone, isSunrise: false)
    }

    private static func solarEvent(on date: Date, latitude: Double, longitude: Double, timeZone: TimeZone, isSunrise: Bool) -> Date? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        guard let dayDate = cal.date(from: comps) else { return nil }
        let n1 = floor(275.0 * Double(comps.month ?? 1) / 9.0)
        let n2 = floor(Double((comps.month ?? 1) + 9) / 12.0)
        let k = 1 + floor(Double(comps.year ?? 2000) - 4.0 * floor(Double((comps.year ?? 2000))/4.0) + 2.0)
        let dayOfYear = Int(n1) - Int(n2) * Int(k) + (comps.day ?? 1) - 30

        let lngHour = longitude / 15.0
        let t = (Double(dayOfYear) + ((isSunrise ? 6.0 : 18.0) - lngHour) / 24.0)
        let M = (0.9856 * t) - 3.289
        let L = normalize360(M + (1.916 * sinDeg(M)) + (0.020 * sinDeg(2*M)) + 282.634)
        let RA = normalize360(atan2Deg(0.91764 * tanDeg(L), 1.0))
        let Lquadrant = floor(L/90.0) * 90.0
        let RAquadrant = floor(RA/90.0) * 90.0
        let RAadj = (RA + (Lquadrant - RAquadrant)) / 15.0
        let sinDec = 0.39782 * sinDeg(L)
        let cosDec = cos(asin(sinDec))
        let cosH = (cosDeg(90.833) - (sinDec * sinDeg(latitude))) / (cosDec * cosDeg(latitude))
        if cosH > 1 && isSunrise { return nil }
        if cosH < -1 && !isSunrise { return nil }
        let H = isSunrise ? (360.0 - acosDeg(cosH)) : acosDeg(cosH)
        let Hhours = H / 15.0
        let T = Hhours + RAadj - (0.06571 * t) - 6.622
        let UT = normalize24(T - lngHour)
        let tzHours = Double(timeZone.secondsFromGMT(for: dayDate)) / 3600.0
        let localT = UT + tzHours
        let hour = Int(floor(localT))
        let minF = (localT - Double(hour)) * 60.0
        let minute = Int(floor(minF))
        let second = Int(floor((minF - Double(minute)) * 60.0))
        var out = comps
        out.hour = hour
        out.minute = minute
        out.second = second
        return cal.date(from: out)
    }

    private static func normalize360(_ x: Double) -> Double { let y = fmod(x, 360.0); return y < 0 ? y + 360.0 : y }
    private static func normalize24(_ x: Double) -> Double { var v = fmod(x, 24.0); if v < 0 { v += 24.0 }; return v }
    private static func sinDeg(_ d: Double) -> Double { sin(d * .pi / 180.0) }
    private static func cosDeg(_ d: Double) -> Double { cos(d * .pi / 180.0) }
    private static func tanDeg(_ d: Double) -> Double { tan(d * .pi / 180.0) }
    private static func acosDeg(_ x: Double) -> Double { acos(x) * 180.0 / .pi }
    private static func atan2Deg(_ y: Double, _ x: Double) -> Double { atan2(y, x) * 180.0 / .pi }
}

