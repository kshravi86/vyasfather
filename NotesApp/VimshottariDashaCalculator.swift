import Foundation

// MARK: - Models

struct BirthDetails {
    let name: String?
    let dateTime: Date
    let timeZone: TimeZone
    let latitude: Double
    let longitude: Double
}

struct DashaPeriod {
    let lord: String
    let startDate: Date
    let endDate: Date
}

// MARK: - Dasha Calculator

final class VimshottariDashaCalculator {

    // Planetary order and durations
    private static let order: [(lord: String, years: Double)] = [
        ("Ketu", 7.0),
        ("Venus", 20.0),
        ("Sun", 6.0),
        ("Moon", 10.0),
        ("Mars", 7.0),
        ("Rahu", 18.0),
        ("Jupiter", 16.0),
        ("Saturn", 19.0),
        ("Mercury", 17.0)
    ]

    private static let nakshatraLength = 360.0 / 27.0  // 13.333°
    private static let daysPerYear = 365.25

    // MARK: - Main Calculation

    static func calculateVimshottariDasha(
        birthDetails: BirthDetails,
        moonSiderealLongitude: Double
    ) -> [DashaPeriod] {

        var periods: [DashaPeriod] = []
        var currentDate = birthDetails.dateTime

        // Step 1: Normalize moon degree
        let moonDegree = normalize(moonSiderealLongitude)

        // Step 2: Find nakshatra index
        let rawIndex = Int(floor(moonDegree / nakshatraLength))
        let nakIndex = Swift.max(0, Swift.min(26, rawIndex))

        // Step 3: Calculate position within nakshatra
        let padaFraction = (moonDegree.truncatingRemainder(dividingBy: nakshatraLength)) / nakshatraLength
        let remainingFraction = 1.0 - padaFraction

        // Step 4: Determine starting lord
        let lordStartIndex = nakIndex % order.count

        // Step 5: First partial period
        let firstLord = order[lordStartIndex]
        let firstDurationDays = firstLord.years * remainingFraction * daysPerYear
        let firstEndDate = currentDate.addingTimeInterval(firstDurationDays * 86400)

        periods.append(DashaPeriod(
            lord: firstLord.lord,
            startDate: currentDate,
            endDate: firstEndDate
        ))

        currentDate = firstEndDate

        // Step 6: Continue with full periods until 120 years
        var elapsedYears = firstLord.years * remainingFraction
        var planetIndex = (lordStartIndex + 1) % order.count

        while elapsedYears < 120.0 - 1e-6 {
            let planet = order[planetIndex]
            let durationDays = planet.years * daysPerYear
            let endDate = currentDate.addingTimeInterval(durationDays * 86400)

            periods.append(DashaPeriod(
                lord: planet.lord,
                startDate: currentDate,
                endDate: endDate
            ))

            currentDate = endDate
            elapsedYears += planet.years
            planetIndex = (planetIndex + 1) % order.count
        }

        return periods
    }

    // MARK: - Antardasha Calculation

    static func calculateAntardasha(for mahadasha: DashaPeriod) -> [DashaPeriod] {
        let totalDays = mahadasha.endDate.timeIntervalSince(mahadasha.startDate) / 86400.0
        let startIndex = indexOfLord(mahadasha.lord)

        var antardashas: [DashaPeriod] = []
        var currentDate = mahadasha.startDate

        for i in 0..<order.count {
            let planet = order[(startIndex + i) % order.count]
            let days = totalDays * (planet.years / 120.0)
            let endDate = currentDate.addingTimeInterval(days * 86400)

            antardashas.append(DashaPeriod(
                lord: planet.lord,
                startDate: currentDate,
                endDate: endDate
            ))

            currentDate = endDate
        }

        return antardashas
    }

    // MARK: - Pratyantar Calculation

    static func calculatePratyantar(for antardasha: DashaPeriod) -> [DashaPeriod] {
        let totalDays = antardasha.endDate.timeIntervalSince(antardasha.startDate) / 86400.0
        let startIndex = indexOfLord(antardasha.lord)

        var pratyantars: [DashaPeriod] = []
        var currentDate = antardasha.startDate

        for i in 0..<order.count {
            let planet = order[(startIndex + i) % order.count]
            let days = totalDays * (planet.years / 120.0)
            let endDate = currentDate.addingTimeInterval(days * 86400)

            pratyantars.append(DashaPeriod(
                lord: planet.lord,
                startDate: currentDate,
                endDate: endDate
            ))

            currentDate = endDate
        }

        return pratyantars
    }

    // MARK: - Helper Functions

    private static func indexOfLord(_ lord: String) -> Int {
        return order.firstIndex { $0.lord.lowercased() == lord.lowercased() } ?? 0
    }

    private static func normalize(_ degree: Double) -> Double {
        var result = degree.truncatingRemainder(dividingBy: 360.0)
        if result < 0 { result += 360.0 }
        return result
    }
}

// (Removed Int.clamped extension to avoid redeclaration across files)
