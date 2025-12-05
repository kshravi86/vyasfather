import Foundation
import CoreLocation

/// Lightweight descriptor for a single stat card rendered on the dashboard.
struct DashboardStatDescriptor: Identifiable, Equatable {
    let id: String
    let title: String
    let value: String
    let icon: String
    let subtitle: String
}

/// Normalised payload of user selections and calculation outputs used to render
/// dashboard strings. Keeping this together avoids recomputing the same values
/// across the various summary helpers.
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

/// Pure functions that translate calculator outputs into short human-facing
/// strings for the dashboard header and stat cards. This keeps ContentView slim
/// and makes string construction easier to unit test later.
enum DashboardSummaryBuilder {
    /// Generates the marquee line beneath the dashboard title based on the
    /// richest piece of available data (Moon > Ascendant > placeholder).
    static func heroLine(for input: DashboardSummaryInput) -> String {
        if input.planetPositions.isEmpty {
            return "Provide birth inputs to unlock personalised dashas, yogas and auspicious timings."
        }
        if let moon = input.planetPositions.first(where: { $0.name == "Moon" }) {
            return "Moon resides in \(AngleFormatter.describe(position: moon)) \(moon.nakshatra) pada \(moon.pada) guiding the mind's rhythm today."
        }
        if let asc = input.ascendant {
            return "Ascendant anchored in \(AngleFormatter.describe(sign: asc.sign, degrees: asc.deg, minutes: asc.min)) is ready for exploration."
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
        let lat = AngleFormatter.coordinate(coordinate.latitude, positiveHemisphere: "N", negativeHemisphere: "S")
        let lon = AngleFormatter.coordinate(coordinate.longitude, positiveHemisphere: "E", negativeHemisphere: "W")
        return "\(lat), \(lon)"
    }

    static func syncBadgeText(for input: DashboardSummaryInput) -> String {
        input.planetPositions.isEmpty ? "Awaiting data" : "Synced"
    }

    /// Describes the recency or failure state of the last Swiss Ephemeris sync so
    /// the dashboard badge can show actionable context.
    static func syncBadgeDetail(
        for input: DashboardSummaryInput,
        now: Date = Date(),
        relativeFormatter: RelativeDateTimeFormatter = defaultRelativeFormatter
    ) -> String {
        // Surface the last ephemeris failure, otherwise render a relative sync age.
        if let calcError = input.calcError {
            return calcError
        }
        guard let last = input.lastSyncedAt else {
            return "Adjust birth inputs to refresh"
        }
        let relative = relativeFormatter.localizedString(for: last, relativeTo: now)
        return "Updated \(relative)"
    }

    /// Builds the stat cards shown under the dashboard hero section. All strings
    /// are derived from the same input so every tile stays consistent.
    static func statDescriptors(
        for input: DashboardSummaryInput,
        dateFormatter: DateFormatter,
        timeFormatter: DateFormatter,
        relativeFormatter: RelativeDateTimeFormatter = defaultRelativeFormatter,
        now: Date = Date()
    ) -> [DashboardStatDescriptor] {
        // Dashboard tiles read from the same core inputs to prevent divergence
        // between what the UI shows and what the calculation engine consumed.
        [
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
