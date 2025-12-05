import XCTest
@testable import NotesApp

final class UtilityFormattingTests: XCTestCase {
    func testGoalMlUsesDefaultsWhenNil() {
        // 70kg default with medium activity => 70 * 35 + 350 = 2800
        let goal = HydrationCalculator.goalMl(weightKg: nil, activity: nil)
        XCTAssertEqual(goal, 2_800)
    }

    func testGoalMlEnforcesMinimumFloor() {
        // Very low weight should still respect the 1500ml minimum.
        let goal = HydrationCalculator.goalMl(weightKg: 20, activity: .low)
        XCTAssertEqual(goal, 1_500)
    }

    func testAngleFormatterDescribe() {
        let description = AngleFormatter.describe(sign: "Leo", degrees: 12, minutes: 5)
        XCTAssertEqual(description, "Leo 12°05'")
    }

    func testCoordinateFormatterUsesHemisphere() {
        let south = AngleFormatter.coordinate(-45.678, positiveHemisphere: "N", negativeHemisphere: "S")
        XCTAssertEqual(south, "45.68° S")

        let east = AngleFormatter.coordinate(77.5946, positiveHemisphere: "E", negativeHemisphere: "W")
        XCTAssertEqual(east, "77.59° E")
    }

    func testFormatDurationProducesCompactString() throws {
        var comps = DateComponents()
        comps.calendar = Calendar(identifier: .gregorian)
        comps.timeZone = TimeZone(abbreviation: "UTC")
        comps.year = 2023
        comps.month = 1
        comps.day = 1
        guard let start = comps.date else { XCTFail("Invalid start date"); return }
        comps.year = 2024
        comps.month = 3
        comps.day = 5
        guard let end = comps.date else { XCTFail("Invalid end date"); return }

        XCTAssertEqual(formatDuration(start: start, end: end), "1y 2m 4d")
    }
}
