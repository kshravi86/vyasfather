import Foundation

/// Shared helpers to present degrees/minutes and coordinates in user-friendly strings.
enum AngleFormatter {
    private static let degreeSymbol = "\u{00B0}"

    static func format(degrees: Int, minutes: Int) -> String {
        let paddedMinutes = String(format: "%02d", minutes)
        return "\(degrees)\(degreeSymbol)\(paddedMinutes)'"
    }

    static func describe(sign: String, degrees: Int, minutes: Int) -> String {
        "\(sign) \(format(degrees: degrees, minutes: minutes))"
    }

    static func describe(position: PlanetPosition) -> String {
        describe(sign: position.sign, degrees: position.deg, minutes: position.min)
    }

    static func coordinate(_ value: Double, positiveHemisphere: String, negativeHemisphere: String) -> String {
        let hemisphere = value >= 0 ? positiveHemisphere : negativeHemisphere
        let magnitude = abs(value)
        return String(format: "%.2f%@ %@", magnitude, degreeSymbol, hemisphere)
    }
}

/// Formats an inclusive date interval into a short human string (e.g. "Jan 1, 2024 - Jan 3, 2024").
func formatDateRange(start: Date, end: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
}

/// Formats the duration between two dates into a compact y/m/d string (e.g. "1y 2m 3d").
func formatDuration(start: Date, end: Date) -> String {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .current
    let comps = cal.dateComponents([.year, .month, .day], from: start, to: end)
    let y = comps.year ?? 0
    let m = comps.month ?? 0
    let d = comps.day ?? 0
    var parts: [String] = []
    if y != 0 { parts.append("\(y)y") }
    if m != 0 { parts.append("\(m)m") }
    if d != 0 || parts.isEmpty { parts.append("\(d)d") }
    return parts.joined(separator: " ")
}
