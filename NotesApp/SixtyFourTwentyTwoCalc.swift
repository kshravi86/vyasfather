import Foundation

struct SixtyFourTwentyTwoResultModel {
    let fromLagnaDrekkanaSign: String
    let fromLagnaDrekkanaNo: Int
    let fromLagnaDrekkanaLord: String
    let fromLagnaDrekkanaStartMin: Int
    let fromLagnaDrekkanaEndMin: Int
    let fromLagnaNavamsaSign: String
    let fromLagnaNavamsaNo: Int
    let fromLagnaNavamsaLord: String
    let fromLagnaNavamsaStartMin: Int
    let fromLagnaNavamsaEndMin: Int

    let fromMoonDrekkanaSign: String
    let fromMoonDrekkanaNo: Int
    let fromMoonDrekkanaLord: String
    let fromMoonDrekkanaStartMin: Int
    let fromMoonDrekkanaEndMin: Int
    let fromMoonNavamsaSign: String
    let fromMoonNavamsaNo: Int
    let fromMoonNavamsaLord: String
    let fromMoonNavamsaStartMin: Int
    let fromMoonNavamsaEndMin: Int
}

enum SixtyFourTwentyTwoCalcIOS {
    private static func signIndex(for name: String) -> Int { ZodiacSign.from(name: name)?.rawValue ?? 0 }
    private static func signName(for idx: Int) -> String { ZodiacSign(rawValue: ((idx%12)+12)%12)?.displayName ?? "Aries" }
    private static func inSignDegree(abs: Double) -> Double {
        var d = abs.truncatingRemainder(dividingBy: 360.0); if d < 0 { d += 360.0 }
        var ins = d.truncatingRemainder(dividingBy: 30.0); if ins < 0 { ins += 30.0 }
        return ins
    }
    private static func drekkanaNo(_ inSign: Double) -> Int { Int(floor(inSign/10.0)) + 1 }
    private static func navamsaNo(_ inSign: Double) -> Int { Int(floor(inSign/(30.0/9.0))) + 1 }
    private static func eighthFrom(_ idx: Int) -> Int { (idx + 7) % 12 }
    private static func nthFrom(_ idx: Int, _ steps: Int) -> Int { (idx + steps) % 12 }

    private static func drekkanaLordFor(signIdx: Int, dreNo: Int) -> String {
        let target = (dreNo == 1) ? signIdx : (dreNo == 2 ? nthFrom(signIdx, 4) : nthFrom(signIdx, 8))
        return signLord(of: target)
    }
    private static func navamsaSignFor(signIdx: Int, navNo: Int) -> Int {
        let sign = ((signIdx%12)+12)%12
        let startOffset: Int
        switch sign {
        case 0,3,6,9: startOffset = 0   // movable
        case 1,4,7,10: startOffset = 8  // fixed → 9th
        default: startOffset = 4        // dual → 5th
        }
        return (sign + startOffset + (navNo - 1)) % 12
    }
    private static func signLord(of signIdx: Int) -> String {
        switch ((signIdx%12)+12)%12 {
        case 0: return "Mars"
        case 1: return "Venus"
        case 2: return "Mercury"
        case 3: return "Moon"
        case 4: return "Sun"
        case 5: return "Mercury"
        case 6: return "Venus"
        case 7: return "Mars"
        case 8: return "Jupiter"
        case 9: return "Saturn"
        case 10: return "Saturn"
        default: return "Jupiter"
        }
    }

    static func compute(ascendant: (sign: String, deg: Int, min: Int)?, planetPositions: [PlanetPosition]) -> SixtyFourTwentyTwoResultModel {
        let ascIdx = signIndex(for: ascendant?.sign ?? "Aries")
        let ascAbs = Double(ascIdx) * 30.0 + Double(ascendant?.deg ?? 0) + Double(ascendant?.min ?? 0)/60.0
        let ascInSign = inSignDegree(abs: ascAbs)
        let ascDrekNo = drekkanaNo(ascInSign)
        let ascNavNo = navamsaNo(ascInSign)
        let ascEighthIdx = eighthFrom(ascIdx)
        let ascDrekLord = drekkanaLordFor(signIdx: ascEighthIdx, dreNo: ascDrekNo)
        let ascNavSignIdx = navamsaSignFor(signIdx: ascEighthIdx, navNo: ascNavNo)
        let ascNavLord = signLord(of: ascNavSignIdx)
        let ascDrekStart = (ascDrekNo - 1) * 600
        let ascDrekEnd = ascDrekNo * 600
        let ascNavStart = (ascNavNo - 1) * 200
        let ascNavEnd = ascNavNo * 200

        let moon = planetPositions.first { $0.name == "Moon" }
        let moonIdx = signIndex(for: moon?.sign ?? ascendant?.sign ?? "Aries")
        let moonInSign = inSignDegree(abs: moon?.longitude ?? ascAbs)
        let moonDrekNo = drekkanaNo(moonInSign)
        let moonNavNo = navamsaNo(moonInSign)
        let moonEighthIdx = eighthFrom(moonIdx)
        let moonDrekLord = drekkanaLordFor(signIdx: moonEighthIdx, dreNo: moonDrekNo)
        let moonNavSignIdx = navamsaSignFor(signIdx: moonEighthIdx, navNo: moonNavNo)
        let moonNavLord = signLord(of: moonNavSignIdx)
        let moonDrekStart = (moonDrekNo - 1) * 600
        let moonDrekEnd = moonDrekNo * 600
        let moonNavStart = (moonNavNo - 1) * 200
        let moonNavEnd = moonNavNo * 200

        return SixtyFourTwentyTwoResultModel(
            fromLagnaDrekkanaSign: signName(for: ascEighthIdx),
            fromLagnaDrekkanaNo: ascDrekNo,
            fromLagnaDrekkanaLord: ascDrekLord,
            fromLagnaDrekkanaStartMin: ascDrekStart,
            fromLagnaDrekkanaEndMin: ascDrekEnd,
            fromLagnaNavamsaSign: signName(for: ascNavSignIdx),
            fromLagnaNavamsaNo: ascNavNo,
            fromLagnaNavamsaLord: ascNavLord,
            fromLagnaNavamsaStartMin: ascNavStart,
            fromLagnaNavamsaEndMin: ascNavEnd,

            fromMoonDrekkanaSign: signName(for: moonEighthIdx),
            fromMoonDrekkanaNo: moonDrekNo,
            fromMoonDrekkanaLord: moonDrekLord,
            fromMoonDrekkanaStartMin: moonDrekStart,
            fromMoonDrekkanaEndMin: moonDrekEnd,
            fromMoonNavamsaSign: signName(for: moonNavSignIdx),
            fromMoonNavamsaNo: moonNavNo,
            fromMoonNavamsaLord: moonNavLord,
            fromMoonNavamsaStartMin: moonNavStart,
            fromMoonNavamsaEndMin: moonNavEnd
        )
    }
}

