import Foundation

// MARK: - Models

/// Birth details required to anchor the Vimshottari Dasha timeline to a real calendar date.
struct BirthDetails {
    let name: String?
    let dateTime: Date
    let timeZone: TimeZone
    let latitude: Double
    let longitude: Double
}

/// A single Mahadasha, Antardasha, Pratyantar, or Sookshma period.
/// The `lord` identifies the ruling planet; start/end mark the exact calendar window.
struct DashaPeriod {
    let lord: String
    let startDate: Date
    let endDate: Date
}

// MARK: - Dasha Calculator

/// Calculates the Vimshottari Dasha timeline using sidereal Moon longitude.
///
/// **System overview**
/// Vimshottari ("120") assigns each of the 27 nakshatras a ruling planet in a fixed
/// 9-planet cycle (Ketu → Venus → Sun → Moon → Mars → Rahu → Jupiter → Saturn → Mercury).
/// The total cycle spans 120 years. At birth the Moon's nakshatra determines which planet
/// rules first, and the fraction of that nakshatra already traversed determines how much of
/// the first period has elapsed before birth.
///
/// Each Mahadasha subdivides into Antardashas (9 sub-periods proportional to each planet's
/// Mahadasha years × sub-planet share of 120). Pratyantar and Sookshma apply the same
/// proportional rule recursively.
final class VimshottariDashaCalculator {

    /// Planet order and their full Mahadasha duration in years. Total = 120 years.
    private static let order: [(lord: String, years: Double)] = [
        ("Ketu",    7.0),
        ("Venus",  20.0),
        ("Sun",     6.0),
        ("Moon",   10.0),
        ("Mars",    7.0),
        ("Rahu",   18.0),
        ("Jupiter",16.0),
        ("Saturn", 19.0),
        ("Mercury",17.0)
    ]

    /// Width of one nakshatra in ecliptic degrees (360 / 27).
    private static let nakshatraLength = 360.0 / 27.0  // ≈ 13.333°

    /// Julian-to-calendar conversion factor used throughout dasha date arithmetic.
    private static let daysPerYear = 365.25

    // MARK: - Main Calculation

    /// Builds the complete Mahadasha sequence anchored to the birth Moon nakshatra.
    ///
    /// - Parameters:
    ///   - birthDetails: Birth date/time and location used as the dasha epoch.
    ///   - moonSiderealLongitude: Sidereal ecliptic longitude of the Moon at birth (0–360°).
    /// - Returns: Ordered array of `DashaPeriod` values covering the full 120-year cycle,
    ///            starting with a partial first period whose length reflects the Moon's
    ///            position within its birth nakshatra.
    static func calculateVimshottariDasha(
        birthDetails: BirthDetails,
        moonSiderealLongitude: Double
    ) -> [DashaPeriod] {

        var periods: [DashaPeriod] = []
        var currentDate = birthDetails.dateTime

        // Clamp Moon degree to [0, 360).
        let moonDegree = normalize(moonSiderealLongitude)

        // Which of the 27 nakshatras does the Moon occupy? (0-based index 0..26)
        let rawIndex = Int(floor(moonDegree / nakshatraLength))
        let nakIndex = Swift.max(0, Swift.min(26, rawIndex))

        // How far through the nakshatra has the Moon already moved (0.0 = start, 1.0 = end)?
        let padaFraction = (moonDegree.truncatingRemainder(dividingBy: nakshatraLength)) / nakshatraLength
        // The remaining fraction determines how much of the first period is still ahead.
        let remainingFraction = 1.0 - padaFraction

        // Each nakshatra maps to one planet via the 9-planet cycle. The nakshatra index
        // mod 9 gives the position in the `order` array.
        let lordStartIndex = nakIndex % order.count

        // First period: only the unelapsed fraction of the nakshatra lord's full duration.
        let firstLord = order[lordStartIndex]
        let firstDurationDays = firstLord.years * remainingFraction * daysPerYear
        let firstEndDate = currentDate.addingTimeInterval(firstDurationDays * 86400)

        periods.append(DashaPeriod(
            lord: firstLord.lord,
            startDate: currentDate,
            endDate: firstEndDate
        ))

        currentDate = firstEndDate

        // Continue with full-length periods until the 120-year cycle is exhausted.
        // The small epsilon (1e-6) guards against floating-point overshoot.
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

    /// Divides a Mahadasha into 9 Antardashas.
    ///
    /// Each Antardasha duration = (Mahadasha total days) × (sub-planet years / 120).
    /// The sub-period sequence starts from the same planet as the Mahadasha lord and
    /// then continues in the standard Vimshottari order.
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

    /// Divides an Antardasha into 9 Pratyantar sub-periods using the same proportional rule.
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

    // MARK: - Sookshma Calculation

    /// Divides a Pratyantar into 9 Sookshma (finest) sub-periods.
    static func calculateSookshma(for pratyantar: DashaPeriod) -> [DashaPeriod] {
        let totalDays = pratyantar.endDate.timeIntervalSince(pratyantar.startDate) / 86400.0
        let startIndex = indexOfLord(pratyantar.lord)

        var sookshmas: [DashaPeriod] = []
        var currentDate = pratyantar.startDate

        for i in 0..<order.count {
            let planet = order[(startIndex + i) % order.count]
            let days = totalDays * (planet.years / 120.0)
            let endDate = currentDate.addingTimeInterval(days * 86400)

            sookshmas.append(DashaPeriod(
                lord: planet.lord,
                startDate: currentDate,
                endDate: endDate
            ))

            currentDate = endDate
        }

        return sookshmas
    }

    // MARK: - Helper Functions

    /// Returns the 0-based index of `lord` in the fixed planet `order` array.
    /// Falls back to 0 (Ketu) if the name is unrecognised.
    private static func indexOfLord(_ lord: String) -> Int {
        return order.firstIndex { $0.lord.lowercased() == lord.lowercased() } ?? 0
    }

    /// Normalises an ecliptic longitude to [0, 360).
    private static func normalize(_ degree: Double) -> Double {
        var result = degree.truncatingRemainder(dividingBy: 360.0)
        if result < 0 { result += 360.0 }
        return result
    }
}

// (Removed Int.clamped extension to avoid redeclaration across files)
