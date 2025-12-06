import XCTest
@testable import BirthInfo

final class MatchmakingEngineTests: XCTestCase {
    func testBuildsProfileFromPositions() {
        let positions: [PlanetPosition] = [
            PlanetPosition(name: "Moon", longitude: 0, sign: "Aries", deg: 5, min: 15, nakshatra: "Ashwini", pada: 1, retrograde: false),
            PlanetPosition(name: "Sun", longitude: 30, sign: "Taurus", deg: 0, min: 0, nakshatra: "Krittika", pada: 2, retrograde: false)
        ]
        let profile = MatchmakingEngine.profile(from: positions, ascendant: (sign: "Leo", deg: 10, min: 0))
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.moonNakshatra, "Ashwini")
        XCTAssertEqual(profile?.moonSign, "Aries")
        XCTAssertEqual(profile?.ascendantSign, "Leo")
    }

    func testCompatibilityProvidesVerdictAndScore() {
        let primary = MatchProfile(moonNakshatra: "Ashwini", moonSign: "Aries", ascendantSign: "Leo")
        let partner = MatchProfile(moonNakshatra: "Rohini", moonSign: "Taurus", ascendantSign: "Sagittarius")

        let result = MatchmakingEngine.evaluate(primary: primary, partner: partner)
        XCTAssertGreaterThan(result.score, 0)
        XCTAssertFalse(result.verdict.isEmpty)
        XCTAssertTrue(result.taraNote.contains("Tara"))
        XCTAssertTrue(result.elementNote.contains("Elements"))
        XCTAssertTrue(result.ascendantNote.contains("Ascendants"))
    }
}
