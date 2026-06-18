import OSLog

/// Centralised `Logger` instances for the app, one per functional category.
///
/// Usage:
///   AppLogger.ephemeris.debug("Loaded \(count) .se1 files")
///   AppLogger.dasha.error("No nakshatra found for longitude \(lon)")
///
/// All loggers share the app's bundle-identifier as their subsystem so that
/// Console.app and `log stream --subsystem <id>` can filter them uniformly.
/// Each category maps to a distinct area of the domain so logs can be further
/// scoped at runtime, e.g. `log stream --predicate 'subsystem == "..." && category == "Dasha"'`.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.vedic.light"

    /// Swiss Ephemeris bridge: file-path resolution, Julian Day conversion, planet lookups.
    static let ephemeris = Logger(subsystem: subsystem, category: "Ephemeris")

    /// Vimshottari Dasha timeline calculations (Maha, Antar, Pratyantar, Sookshma).
    static let dasha = Logger(subsystem: subsystem, category: "Dasha")

    /// Panchanga calculations (Tithi, Vara, Nakshatra, Yoga, Karana).
    static let panchanga = Logger(subsystem: subsystem, category: "Panchanga")

    /// Matchmaking / Ashtakoota compatibility engine.
    static let matchmaking = Logger(subsystem: subsystem, category: "Matchmaking")

    /// Jaimini Karakas, Arudha Padas, and Lagnas.
    static let jaimini = Logger(subsystem: subsystem, category: "Jaimini")

    /// Yogi / Avayogi point and Sahayogi calculations.
    static let yogi = Logger(subsystem: subsystem, category: "Yogi")

    /// Ishta Devata / Palana Devata derivation.
    static let ishtaDevata = Logger(subsystem: subsystem, category: "IshtaDevata")

    /// Varga / divisional chart calculations (D9 Navamsha, D7 Saptamsha, etc.).
    static let varga = Logger(subsystem: subsystem, category: "Varga")

    /// UI-level events: tab switches, snapshot captures, settings changes.
    static let ui = Logger(subsystem: subsystem, category: "UI")
}
