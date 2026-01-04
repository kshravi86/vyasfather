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

    func testFavourablePairScoresHigh() {
        let primary = MatchProfile(moonNakshatra: "Ashwini", moonSign: "Aries", ascendantSign: "Aries")
        let partner = MatchProfile(moonNakshatra: "Bharani", moonSign: "Gemini", ascendantSign: "Leo")

        let result = MatchmakingEngine.evaluate(primary: primary, partner: partner)

        XCTAssertEqual(result.score, 78) // 50 base + 12 tara + 8 element + 8 asc
        XCTAssertEqual(result.verdict, "Strong harmony")
        XCTAssertEqual(result.summary, "Moon: Ashwini & Bharani | Asc: Aries & Leo")
        XCTAssertTrue(result.taraNote.contains("favourable rhythm"))
        XCTAssertTrue(result.elementNote.contains("complementary flow"))
        XCTAssertTrue(result.ascendantNote.contains("supportive angles"))
    }

    func testChallengingPairScoresLow() {
        let primary = MatchProfile(moonNakshatra: "Ashwini", moonSign: "Aries", ascendantSign: "Aries")
        let partner = MatchProfile(moonNakshatra: "Rohini", moonSign: "Cancer", ascendantSign: "Libra")

        let result = MatchmakingEngine.evaluate(primary: primary, partner: partner)

        XCTAssertEqual(result.score, 31) // 50 base - 8 tara - 6 element - 5 asc
        XCTAssertEqual(result.verdict, "Needs conscious effort")
        XCTAssertTrue(result.taraNote.contains("sensitive combination"))
        XCTAssertTrue(result.elementNote.contains("contrasting flow"))
        XCTAssertTrue(result.ascendantNote.contains("opposing axis"))
        XCTAssertEqual(result.summary, "Moon: Ashwini & Rohini | Asc: Aries & Libra")
    }

    func testMissingAscendantKeepsNeutralAscNote() {
        let primary = MatchProfile(moonNakshatra: "Ashwini", moonSign: "Aries", ascendantSign: "Aries")
        let partner = MatchProfile(moonNakshatra: "Bharani", moonSign: "Taurus", ascendantSign: nil)

        let result = MatchmakingEngine.evaluate(primary: primary, partner: partner)

        XCTAssertEqual(result.score, 64) // 50 base + 12 tara + 2 neutral elements, asc delta 0
        XCTAssertEqual(result.verdict, "Balanced potential")
        XCTAssertTrue(result.ascendantNote.contains("awaiting partner chart"))
        XCTAssertEqual(result.summary, "Moon: Ashwini & Bharani | Asc: Aries & -")
    }
}
