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
