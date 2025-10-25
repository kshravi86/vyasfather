# How Lagnas Page Logic is Implemented

The "Lagnas" page in this application is designed to calculate and display various special Lagnas (ascendants) based on a user's birth details. The logic is primarily split between two files:

1.  `LagnasTabView.swift`: Handles the user interface and orchestrates the data flow.
2.  `SpecialLagnasCalc.swift`: Contains the core astrological calculation logic for the special Lagnas.

## `LagnasTabView.swift` (View Layer)

This SwiftUI `View` is responsible for presenting the calculated Lagnas to the user. Its main functions include:

*   **Input Parameters**: It receives `dateOfBirth`, `timeOfBirth`, `coordinate` (CLLocationCoordinate2D), `planetPositions` (an array of `PlanetPosition`), and `ascendant` (natal ascendant sign, degree, minute) as inputs, which are crucial for the calculations.
*   **Data Preparation**: It includes helper functions like `merge(date:time:in:)` to combine date and time into a single `Date` object, and `convertToLagnaTuple(_:)` to transform the calculation models (`GhatikaLagnaModel`, `HoraLagnaModel`, `InduLagnaModel`) into a display-friendly tuple `(sign: String, deg: Int, min: Int)?`.
*   **Calculation Invocation**: Within its `body`, it calls static methods from `SpecialLagnasCalc` to perform the actual calculations:
    *   `SpecialLagnasCalc.ghatikaLagna(...)`
    *   `SpecialLagnasCalc.horaLagna(...)`
    *   `SpecialLagnasCalc.horaLagnaJaimini(...)`
    *   `SpecialLagnasCalc.induLagna(...)`
*   **User Interface**: It uses SwiftUI components like `ScrollView`, `LazyVStack`, and `LazyVGrid` to lay out the information. Each special Lagna is displayed using an `enhancedLagnaCard` view, which shows the Lagna's sign, degree, and minute, along with a description.
*   **State Handling**: It displays a `loadingStateView()` if the `coordinate` (location data) is not yet available.
*   **Styling**: It utilizes `CosmicTheme` for consistent visual styling across the app.

## `SpecialLagnasCalc.swift` (Calculation Logic Layer)

This `enum` acts as a utility class containing static methods for performing the complex astrological calculations for each special Lagna. Key components and calculations include:

*   **`normalize360(_ x: Double)`**: A private utility function to ensure all longitude values are normalized within a 0-360 degree range.

*   **`ghatikaLagna(date:tz:coord:calculator:)`**:
    *   **Purpose**: Represents the timing of important events in life.
    *   **Calculation**: It first determines the sunrise time for the given date and location using `SunriseCalcIOS`. It then calculates the Sun's longitude at that sunrise time. The Ghatika Lagna's longitude is derived by adding an advancement of 1.25 degrees for every minute elapsed since sunrise to the Sun's longitude at sunrise.

*   **`horaLagna(date:tz:coord:natalAscAbs:calculator:)`**:
    *   **Purpose**: Indicates wealth, material gains, and financial prospects.
    *   **Calculation**: Similar to Ghatika Lagna, it starts with sunrise time and Sun's longitude. It calculates "Ishta Hours" (hours elapsed since sunrise). The Hora Lagna's longitude is found by advancing the Sun's longitude at sunrise by 30 degrees for every hour elapsed since sunrise. It also determines the house position of Hora Lagna relative to the natal ascendant.

*   **`horaLagnaJaimini(date:tz:coord:calculator:)`**:
    *   **Purpose**: An alternative method for Hora Lagna calculation based on Jaimini astrological principles.
    *   **Calculation**: This method also uses sunrise time and Sun's longitude. However, the advancement calculation is different, using a more granular approach based on seconds elapsed since sunrise (30 degrees per hour, 0.5 degrees per minute, and a further fraction for seconds).

*   **`induLagna(planetPositions:ascSignName:)`**:
    *   **Purpose**: A special Lagna specifically for analyzing wealth and prosperity.
    *   **Calculation**: This is a more intricate calculation:
        1.  It identifies the Moon's position from the `planetPositions` and the natal ascendant sign.
        2.  It determines the planetary lords of the 9th house from both the natal ascendant and the Moon's sign using the `signLord(of:)` helper.
        3.  It then uses the `kalaValue(of:)` helper to assign numerical values to these two planetary lords.
        4.  These Kala values are summed, and a remainder after division by 12 is used to determine the Indu Lagna sign, starting from the Moon's sign.
        5.  It also calculates the house position of Indu Lagna from the natal ascendant.

*   **Helper Functions**: `SpecialLagnasCalc` also contains private helper functions:
    *   `sunLongitude(...)`: Retrieves the Sun's longitude for a given date, time, and coordinate using the `PlanetaryCalculator`.
    *   `signLord(of:)`: Maps a `ZodiacSign` to its ruling planet (e.g., Aries -> Mars).
    *   `kalaValue(of:)`: Provides specific numerical values for planets, used in the Indu Lagna calculation.

## Overall Flow

The `LagnasTabView` acts as the presentation layer, responsible for gathering the necessary birth information and displaying the results. It delegates the complex astrological computations to the `SpecialLagnasCalc` utility, which encapsulates all the mathematical and astrological rules for determining each special Lagna. This separation of concerns ensures a clean architecture, making the UI code focused on presentation and the calculation code focused on accuracy and reusability.
