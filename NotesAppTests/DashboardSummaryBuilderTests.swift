import XCTest
import CoreLocation
@testable import NotesApp

final class DashboardSummaryBuilderTests: XCTestCase {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    func testHeroLinePrefersMoonPosition() {
        let moon = PlanetPosition(
            name: "Moon",
            longitude: 45,
            sign: "Taurus",
            deg: 15,
            min: 30,
            nakshatra: "Rohini",
            pada: 2,
            retrograde: false
        )
        let input = makeInput(planetPositions: [moon])

        let line = DashboardSummaryBuilder.heroLine(for: input)

        XCTAssertTrue(line.contains("Taurus"), "Expected moon sign in hero line, got: \(line)")
        XCTAssertTrue(line.contains("Rohini"), "Expected nakshatra in hero line, got: \(line)")
    }

    func testHeroLineFallsBackToAscendant() {
        let input = makeInput(planetPositions: [], ascendant: (sign: "Leo", deg: 5, min: 10))

        let line = DashboardSummaryBuilder.heroLine(for: input)

        XCTAssertTrue(line.contains("Leo"), "Expected ascendant sign in fallback hero line")
    }

    func testLocationDescriptorConcatenatesComponents() {
        let input = makeInput(selectedTitle: "Bengaluru", selectedState: "Karnataka", selectedCountry: "India")
        XCTAssertEqual(
            DashboardSummaryBuilder.locationDescriptor(for: input),
            "Bengaluru, Karnataka, India"
        )
    }

    func testCoordinateDescriptorFormatsLatLong() {
        let coordinate = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)
        let input = makeInput(coordinate: coordinate)

        XCTAssertEqual(
            DashboardSummaryBuilder.coordinateDescriptor(for: input),
            "12.97°, 77.59°"
        )
    }

    func testSyncBadgeDetailUsesRelativeTime() {
        var formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "en_US")
        let now = Date()
        let twoMinutesAgo = now.addingTimeInterval(-120)
        let input = makeInput(lastSyncedAt: twoMinutesAgo)

        let detail = DashboardSummaryBuilder.syncBadgeDetail(for: input, now: now, relativeFormatter: formatter)

        XCTAssertEqual(detail, "Updated 2 minutes ago")
    }

    func testStatDescriptorsReflectBirthMeta() {
        var relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.locale = Locale(identifier: "en_US")
        let now = Date()
        let input = makeInput(
            selectedTitle: "Chennai",
            selectedState: "",
            selectedCountry: "India",
            coordinate: CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707),
            lastSyncedAt: now.addingTimeInterval(-300)
        )

        let stats = DashboardSummaryBuilder.statDescriptors(
            for: input,
            dateFormatter: dateFormatter,
            timeFormatter: timeFormatter,
            relativeFormatter: relativeFormatter,
            now: now
        )

        XCTAssertEqual(stats.count, 4)
        XCTAssertEqual(stats[0].title, "Birth date")
        XCTAssertEqual(stats[1].value, "10:45")
        XCTAssertEqual(stats[2].value, "Chennai, India")
        XCTAssertEqual(stats[3].value, "Synced")
        XCTAssertTrue(stats[3].subtitle.contains("Updated 5 minutes ago"))
    }

    private func makeInput(
        planetPositions: [PlanetPosition] = [],
        ascendant: (sign: String, deg: Int, min: Int)? = nil,
        selectedTitle: String = "Sample City",
        selectedState: String = "",
        selectedCountry: String = "",
        coordinate: CLLocationCoordinate2D? = nil,
        lastSyncedAt: Date? = nil
    ) -> DashboardSummaryInput {
        let date = dateFormatter.date(from: "1993-05-18") ?? Date()
        let time = timeFormatter.date(from: "10:45") ?? Date()
        return DashboardSummaryInput(
            planetPositions: planetPositions,
            ascendant: ascendant,
            dateOfBirth: date,
            timeOfBirth: time,
            selectedTitle: selectedTitle,
            selectedState: selectedState,
            selectedCountry: selectedCountry,
            coordinate: coordinate,
            calcError: nil,
            lastSyncedAt: lastSyncedAt
        )
    }
}
