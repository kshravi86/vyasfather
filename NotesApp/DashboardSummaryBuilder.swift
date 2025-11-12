import Foundation
import CoreLocation

struct DashboardStatDescriptor: Identifiable, Equatable {
    let id: String
    let title: String
    let value: String
    let icon: String
    let subtitle: String
}

struct DashboardSummaryInput {
    var planetPositions: [PlanetPosition]
    var ascendant: (sign: String, deg: Int, min: Int)?
    var dateOfBirth: Date
    var timeOfBirth: Date
    var selectedTitle: String
    var selectedState: String
    var selectedCountry: String
    var coordinate: CLLocationCoordinate2D?
    var calcError: String?
    var lastSyncedAt: Date?
}

enum DashboardSummaryBuilder {
    private static let coordinateFormat = "%.2f°"
    private static let coordinateLocale = Locale(identifier: "en_US_POSIX")

    static func heroLine(for input: DashboardSummaryInput) -> String {
        if input.planetPositions.isEmpty {
            return "Provide birth inputs to unlock personalised dashas, yogas and auspicious timings."
        }
        if let moon = input.planetPositions.first(where: { $0.name == "Moon" }) {
            return "Moon resides in \(moon.sign) ♒︎ \(moon.nakshatra) pada \(moon.pada) guiding the mind's rhythm today."
        }
        if let asc = input.ascendant {
            return "Ascendant anchored in \(asc.sign) at \(asc.deg)°\(asc.min)' is ready for exploration."
        }
        return "Your cosmic dashboard is hydrated with planetary intelligence."
    }

    static func locationDescriptor(for input: DashboardSummaryInput) -> String {
        let parts = [input.selectedTitle, input.selectedState, input.selectedCountry]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? "Select a birthplace" : parts.joined(separator: ", ")
    }

    static func coordinateDescriptor(for input: DashboardSummaryInput) -> String {
        guard let coordinate = input.coordinate else { return "Awaiting location" }
        let lat = String(format: coordinateFormat, locale: coordinateLocale, coordinate.latitude)
        let lon = String(format: coordinateFormat, locale: coordinateLocale, coordinate.longitude)
        return "\(lat), \(lon)"
    }

    static func syncBadgeText(for input: DashboardSummaryInput) -> String {
        input.planetPositions.isEmpty ? "Awaiting data" : "Synced"
    }

    static func syncBadgeDetail(
        for input: DashboardSummaryInput,
        now: Date = Date(),
        relativeFormatter: RelativeDateTimeFormatter = defaultRelativeFormatter
    ) -> String {
        if let calcError = input.calcError {
            return calcError
        }
        guard let last = input.lastSyncedAt else {
            return "Adjust birth inputs to refresh"
        }
        let relative = relativeFormatter.localizedString(for: last, relativeTo: now)
        return "Updated \(relative)"
    }

    static func statDescriptors(
        for input: DashboardSummaryInput,
        dateFormatter: DateFormatter,
        timeFormatter: DateFormatter,
        relativeFormatter: RelativeDateTimeFormatter = defaultRelativeFormatter,
        now: Date = Date()
    ) -> [DashboardStatDescriptor] {
        return [
            DashboardStatDescriptor(
                id: "date",
                title: "Birth date",
                value: dateFormatter.string(from: input.dateOfBirth),
                icon: "calendar",
                subtitle: "Local calendar reference"
            ),
            DashboardStatDescriptor(
                id: "time",
                title: "Birth time",
                value: timeFormatter.string(from: input.timeOfBirth),
                icon: "clock",
                subtitle: "Using local timezone"
            ),
            DashboardStatDescriptor(
                id: "location",
                title: "Location",
                value: locationDescriptor(for: input),
                icon: "mappin.and.ellipse",
                subtitle: coordinateDescriptor(for: input)
            ),
            DashboardStatDescriptor(
                id: "status",
                title: "Ephemeris",
                value: syncBadgeText(for: input),
                icon: "sparkles",
                subtitle: syncBadgeDetail(for: input, now: now, relativeFormatter: relativeFormatter)
            )
        ]
    }

    private static let defaultRelativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}
