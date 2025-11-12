import XCTest
@testable import BirthInfo

final class PlanetKindTests: XCTestCase {
    func testAliasResolutionIsCaseInsensitive() {
        XCTAssertEqual(PlanetKind(label: "Sun"), .sun)
        XCTAssertEqual(PlanetKind(label: "  moon  "), .moon)
        XCTAssertEqual(PlanetKind(label: "BUDHA"), .mercury)
        XCTAssertEqual(PlanetKind(label: "Shukra"), .venus)
        XCTAssertEqual(PlanetKind(label: "Shani"), .saturn)
        XCTAssertNil(PlanetKind(label: "Ascendant"))
    }

    func testMetadataProvidesIconsAndColors() {
        let mars = PlanetKind(label: "Mars")
        XCTAssertEqual(mars?.iconName, "flame.fill")

        let rahu = PlanetKind(label: "Rahu")
        XCTAssertEqual(rahu?.iconName, "arrow.up.circle.fill")
    }

    func testPlanetStyleFallbacks() {
        XCTAssertEqual(PlanetStyle.icon(for: "Unknown"), "circle.fill")
        XCTAssertNotEqual(PlanetStyle.color(for: "Sun"), .white)
    }
}
