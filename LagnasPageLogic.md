# How Lagnas Page Logic is Implemented (Detailed)

The "Lagnas" page calculates and displays various special Lagnas (ascendants). The implementation logic is precisely distributed between two primary files:

1.  `LagnasTabView.swift`: Handles the SwiftUI view, user interaction, and orchestration of data.
2.  `SpecialLagnasCalc.swift`: Contains the core astrological calculation logic for the special Lagnas.

## `LagnasTabView.swift` (View Layer & Orchestration)

This SwiftUI `View` is responsible for presenting the calculated Lagnas and coordinating the data flow from user input to display.

*   **View Initialization and Inputs**
    *   **Filename**: `LagnasTabView.swift`
    *   **Function/Struct**: `struct LagnasTabView: View { ... }`
    *   **Logic**: Initializes the view with `dateOfBirth`, `timeOfBirth`, `coordinate` (CLLocationCoordinate2D), an array of `planetPositions` (e.g., `[PlanetPosition]`), and the `ascendant` (a tuple representing the natal ascendant sign, degree, and minute). These inputs drive the entire Lagna calculation and display process.

*   **Date and Time Merging Utility**
    *   **Filename**: `LagnasTabView.swift`
    *   **Function**: `private func merge(date: Date, time: Date, in tz: TimeZone) -> Date { ... }` and `private var mergedDateTime: Date { ... }`
    *   **Logic**: Combines separate `Date` objects for birth date and birth time into a single `Date` object, adjusted for the specified `tz` (timezone). This unified `Date` is critical for accurate calculations by `SpecialLagnasCalc`.

*   **Calculation Model to Display Tuple Conversion**
    *   **Filename**: `LagnasTabView.swift`
    *   **Functions**: `private func convertToLagnaTuple(_ model: GhatikaLagnaModel?) -> (sign: String, deg: Int, min: Int)? { ... }`, `private func convertToLagnaTuple(_ model: HoraLagnaModel?) -> (sign: String, deg: Int, min: Int)? { ... }`, `private func convertToLagnaTuple(_ model: InduLagnaModel?) -> (sign: String, deg: Int, min: Int)? { ... }`
    *   **Logic**: These helper functions standardize the output from the `SpecialLagnasCalc` models (`GhatikaLagnaModel`, `HoraLagnaModel`, `InduLagnaModel`) into a consistent `(sign: String, deg: Int, min: Int)?` format, making them easy to display in the UI. For `InduLagnaModel`, as it inherently lacks precise degree/minute information in its structure, `deg` and `min` are set to `0` for display purposes.

*   **Main View Body and Calculation Orchestration**
    *   **Filename**: `LagnasTabView.swift`
    *   **Function**: `var body: some View { ... }`
    *   **Logic**: This is the primary rendering block. It conditionally displays content based on the availability of `coordinate`. If `coordinate` is present:
        1.  It obtains the merged birth `Date` (`mergedDateTime`) and the natal ascendant's absolute longitude (`natalAscendantAbsolute`).
        2.  It invokes specific static calculation methods from `SpecialLagnasCalc`:
            *   `let gl = SpecialLagnasCalc.ghatikaLagna(...)`
            *   `let hl = SpecialLagnasCalc.horaLagna(...)`
            *   `let hlj = SpecialLagnasCalc.horaLagnaJaimini(...)`
            *   `let indu = SpecialLagnasCalc.induLagna(...)`
        3.  The results (`gl`, `hl`, `hlj`, `indu`) are then passed to `enhancedLagnaCard` for visual representation within a `ScrollView` and `LazyVGrid` layout.
        4.  If `coordinate` is nil, a `loadingStateView()` is displayed, prompting for birth details.

*   **UI Component Builders**
    *   **Filename**: `LagnasTabView.swift`
    *   **Functions**: `private func headerSection() -> some View { ... }`, `private func enhancedLagnaCard(...) -> some View { ... }`, `private func infoSection() -> some View { ... }`, `private func loadingStateView() -> some View { ... }`, `struct InfoRow: View { ... }`
    *   **Logic**: These private SwiftUI view builders are responsible for the specific visual presentation aspects: a top header, individual interactive cards for each Lagna, an informational section about special Lagnas, a loading screen, and simple rows for information. They utilize `CosmicTheme` for consistent app branding and styling.

## `SpecialLagnasCalc.swift` (Core Calculation Layer)

This `enum` encapsulates all the static methods required for performing the precise astrological calculations of the special Lagnas, using inputs like date, time, location, and planetary positions.

*   **Utility - Angle Normalization**
    *   **Filename**: `SpecialLagnasCalc.swift`
    *   **Function**: `private static func normalize360(_ x: Double) -> Double { ... }`
    *   **Logic**: A fundamental helper to ensure that any calculated ecliptic longitude (degrees) is always returned within the standard 0 to 360-degree range, wrapping around as necessary.

*   **Ghatika Lagna Calculation**
    *   **Filename**: `SpecialLagnasCalc.swift`
    *   **Function**: `static func ghatikaLagna(date: Date, tz: TimeZone, coord: CLLocationCoordinate2D, calculator: PlanetaryCalculator) -> GhatikaLagnaModel? { ... }`
    *   **Logic**: Calculates Ghatika Lagna by:
        1.  Determining the sunrise time for the given `date`, `coord`, and `tz` using `SunriseCalcIOS.sunrise`.
        2.  Obtaining the Sun's longitude at that sunrise time via `sunLongitude`.
        3.  Calculating the total minutes elapsed from sunrise to the input `date`.
        4.  Advancing the Sun's longitude by `1.25 degrees for every minute` elapsed.
        5.  Returning a `GhatikaLagnaModel` containing the final longitude and its corresponding Zodiac sign.

*   **Hora Lagna (Standard Method) Calculation**
    *   **Filename**: `SpecialLagnasCalc.swift`
    *   **Function**: `static func horaLagna(date: Date, tz: TimeZone, coord: CLLocationCoordinate2D, natalAscAbs: Double, calculator: PlanetaryCalculator) -> HoraLagnaModel? { ... }`
    *   **Logic**: Calculates Hora Lagna by:
        1.  Finding the sunrise time and Sun's longitude at sunrise (similar to Ghatika Lagna).
        2.  Calculating "Ishta Hours" (total hours elapsed between sunrise and the input `date`).
        3.  Advancing the Sun's longitude by `30 degrees for every hour` elapsed.
        4.  Determining the Hora Lagna's Zodiac sign and its house position relative to the `natalAscAbs` (natal ascendant's absolute longitude).
        5.  Returning a `HoraLagnaModel` with the calculated longitude, sign, house position, Ishta hours, and sunrise time.

*   **Hora Lagna (Jaimini Method) Calculation**
    *   **Filename**: `SpecialLagnasCalc.swift`
    *   **Function**: `static func horaLagnaJaimini(date: Date, tz: TimeZone, coord: CLLocationCoordinate2D, calculator: PlanetaryCalculator) -> GhatikaLagnaModel? { ... }`
    *   **Logic**: Provides an alternative Hora Lagna calculation:
        1.  Retrieves sunrise time and Sun's longitude.
        2.  Calculates total seconds elapsed since sunrise.
        3.  Applies a more granular advancement to the Sun's longitude: `30 degrees per hour`, `0.5 degrees per minute`, and `(0.5/60) degrees per second`.
        4.  Returns a `GhatikaLagnaModel` (reusing the same data structure, but storing the Jaimini Hora Lagna).

*   **Indu Lagna Calculation**
    *   **Filename**: `SpecialLagnasCalc.swift`
    *   **Function**: `static func induLagna(planetPositions: [PlanetPosition], ascSignName: String) -> InduLagnaModel? { ... }`
    *   **Logic**: A more complex calculation focused on wealth indicators:
        1.  Extracts the Moon's position from `planetPositions` and uses the provided `ascSignName`.
        2.  Identifies the Zodiac signs corresponding to the 9th house from both the natal Ascendant and the Moon's sign.
        3.  Utilizes the `signLord` helper function to determine the traditional planetary rulers for these 9th house signs.
        4.  Applies the `kalaValue` helper function to get specific numerical values for these ruling planets.
        5.  Sums these Kala values (`sum`), then calculates a remainder (`r = sum % 12`). If `r` is `0`, it defaults to `12`.
        6.  The Indu Lagna sign is determined by advancing from the Moon's sign by the remainder value (`r - 1`).
        7.  Calculates the house position of Indu Lagna relative to the natal ascendant.
        8.  Returns an `InduLagnaModel` containing the derived sign, house position, and intermediate calculation values.

*   **Helper - Sun Longitude Retrieval**
    *   **Filename**: `SpecialLagnasCalc.swift`
    *   **Function**: `private static func sunLongitude(at date: Date, tz: TimeZone, coord: CLLocationCoordinate2D, calculator: PlanetaryCalculator) -> Double { ... }`
    *   **Logic**: A utility function that dispatches to the `PlanetaryCalculator` to obtain the Sun's geocentric ecliptic longitude for a precise `Date`, `TimeZone`, and geographic `CLLocationCoordinate2D`.

*   **Helper - Zodiac Sign Lord Mapping**
    *   **Filename**: `SpecialLagnasCalc.swift`
    *   **Function**: `private static func signLord(of sign: ZodiacSign) -> String { ... }`
    *   **Logic**: Maps a given `ZodiacSign` enum value (e.g., `.aries`) to the `String` name of its traditional planetary ruler (e.g., "Mars").

*   **Helper - Kala Value Assignment**
    *   **Filename**: `SpecialLagnasCalc.swift`
    *   **Function**: `private static func kalaValue(of planet: String) -> Int { ... }`
    *   **Logic**: Assigns specific, predefined integer "Kala values" to certain planets (e.g., Sun: 30, Moon: 16), which are used in the Indu Lagna calculation process.