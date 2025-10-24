# Project Calculation Logic Explanation

## Overview
This document explains the core astrological calculation logic implemented in the project, primarily within the `NotesApp` directory. The project leverages the **Swiss Ephemeris** library for precise planetary calculations.

## Core Calculation Modules

### 1. Swiss Ephemeris Integration
*   **Files:** `NotesApp/SwissEphWrapper.m`, `NotesApp/SwissEphBridge.h`, `ThirdParty/SwissEph/src/*`
*   **Purpose:** The Swiss Ephemeris is a high-precision ephemeris library used for calculating planetary positions, house cusps, and other astronomical data. `SwissEphWrapper.m` and `SwissEphBridge.h` provide an Objective-C bridge to integrate the C-based Swiss Ephemeris library into the Swift codebase.
*   **Key Functionality:** Provides raw astrological data based on date, time, and location.

### 2. Planetary Calculations
*   **File:** `NotesApp/PlanetaryCalculator.swift`
*   **Purpose:** This module processes the raw data from Swiss Ephemeris to derive planet positions, signs, degrees, and other relevant planetary information used throughout the app.

### 3. Vimshottari Dasha Calculation
*   **File:** `NotesApp/VimshottariDashaCalculator.swift`
*   **Purpose:** Calculates the Vimshottari Dasha periods (Mahadasha, Antardasha, Pratyantardasha, Sookshma), which are planetary periods used in Vedic astrology for timing events.
*   **Dependencies:** Relies on accurate Moon longitude from planetary calculations.

### 4. 64th Navamsha & 22nd Drekkana Calculation
*   **File:** `NotesApp/SixtyFourTwentyTwoCalc.swift`
*   **Purpose:** Computes the 64th Navamsha Lord and 22nd Drekkana Lord, which are sensitive points in a horoscope indicating potential challenges.
*   **Dependencies:** Requires ascendant and planetary positions.

### 5. Panchanga Calculation
*   **File:** `NotesApp/PanchangaCalc.swift`
*   **Purpose:** Calculates the five limbs of the Vedic day (Tithi, Vara, Nakshatra, Yoga, Karana) based on the date, time, and location.

### 6. Ishta Devata Calculation
*   **File:** `NotesApp/IshtaDevataCalc.swift`
*   **Purpose:** Determines the Ishta Devata (personal deity) based on specific astrological principles, often involving the Atmakaraka planet.

### 7. Yogi, Avayogi, and Duplicate Yogi Calculation
*   **File:** `NotesApp/YogiCalculator.swift`
*   **Purpose:** Identifies the Yogi, Avayogi, and Duplicate Yogi planets/points, which are significant in Vedic astrology for indicating fortune, misfortune, and support.

### 8. Special Lagnas Calculation
*   **File:** `NotesApp/SpecialLagnasCalc.swift`
*   **Purpose:** Calculates various special lagnas (ascendants) such as Hora Lagna, Ghatika Lagna, etc., which are used for specific predictive purposes.

### 9. Varga (Divisional Chart) Calculation
*   **File:** `NotesApp/VargaCalculatorIOS.swift`
*   **Purpose:** Computes divisional charts (Vargas) like Navamsha, Drekkana, Saptamsha, etc., which provide a deeper insight into specific areas of life.

### 10. Jaimini Astrology Calculations
*   **Files:** `NotesApp/JaiminiArudha.swift`, `NotesApp/JaiminiKarakas.swift`
*   **Purpose:** Implements calculations related to Jaimini astrology, including Jaimini Karakas (planetary significators) and Arudha Padas.

### 11. Utility Functions
*   **Files:** `NotesApp/DrekkanaUtils.swift`, `NotesApp/PushkaraUtils.swift`, `NotesApp/SunriseCalcIOS.swift`, `NotesApp/DateUtils.swift`, `NotesApp/Int+Clamp.swift`
*   **Purpose:** These files contain various utility functions that support the main calculation modules, such as date manipulation, astronomical calculations (e.g., sunrise), and specific astrological concepts (e.g., Drekkana, Pushkara).

## Overall Calculation Flow
1.  **Input:** User provides birth details (date, time, location).
2.  **Core Astronomical Data:** `SunriseCalcIOS.swift` and `SwissEphWrapper.m` (via Swiss Ephemeris) are used to calculate precise planetary positions, house cusps, and other astronomical phenomena for the given birth details.
3.  **Planetary Processing:** `PlanetaryCalculator.swift` processes this raw data into a usable format (e.g., planet in sign, degree).
4.  **Derived Calculations:** The processed planetary data and birth details are then fed into various specialized calculators:
    *   `VimshottariDashaCalculator.swift` for Dasha periods.
    *   `SixtyFourTwentyTwoCalc.swift` for sensitive points.
    *   `PanchangaCalc.swift` for daily astrological elements.
    *   `IshtaDevataCalc.swift` for personal deity.
    *   `YogiCalculator.swift` for Yogi points.
    *   `SpecialLagnasCalc.swift` for special ascendants.
    *   `VargaCalculatorIOS.swift` for divisional charts.
    *   `JaiminiArudha.swift` and `JaiminiKarakas.swift` for Jaimini concepts.
5.  **Output:** The results of these calculations are then displayed in the respective UI views (e.g., `DashaTabView`, `SixtyFourTwentyTwoTabView`).