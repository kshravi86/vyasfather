
# Vedic Light iOS App: A Detailed Explanation

## App Overview

The app is a Vedic Astrology application named "Vedic Light". It's built with SwiftUI and calculates various astrological data based on user-provided birth details (date, time, and place).

## Core Functionality

1.  **Birth Data Input:** The `ContentView` is the main screen where users input their date, time, and place of birth. It uses a `LocationSearchManager` to help users find their birthplace and get accurate coordinates.

2.  **Planetary Calculations:** The `PlanetaryCalculator` class is the heart of the app. It uses the Swiss Ephemeris library (via a C bridge `SwissEphBridge.h` and `SwissEphWrapper.m`) to calculate the positions of the planets (Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Rahu, and Ketu) at the time of birth. It also calculates the Ascendant and house cusps. The calculations are done using the Lahiri ayanamsa.

3.  **Astrological Charts and Tables:** The app presents a wide range of astrological information in a tabbed interface. Each tab corresponds to a specific astrological chart or calculation:
    *   **Dasha:** `DashaTabView` and `DashaView` display the Vimshottari Dasha periods, which are planetary cycles. It shows the major periods (Mahadasha), sub-periods (Antardasha), and sub-sub-periods (Pratyantardasha).
    *   **Yogi:** `YogiTabView` and `YogiView` calculate and display the Yogi, Sahayogi, and Avayogi planets, which are important for determining periods of fortune and misfortune.
    *   **Uttama:** `UttamaTabView` determines if planets are in "Uttama Drekkana," a favorable position.
    *   **Jaimini:** `JaiminiTabView` displays Jaimini astrology concepts like Chara Karakas (temporary significators) and Arudha Padas (symbolic representations of houses).
    *   **Panchanga:** `PanchangaTabView` shows the five limbs of the Hindu calendar for the time of birth: Tithi (lunar day), Vara (weekday), Nakshatra (lunar mansion), Yoga (a specific planetary combination), and Karana (half a lunar day).
    *   **Ishta:** `IshtaDevataTabView` calculates the Ishta Devata (personal deity) and Palana Devata (guardian deity) based on the positions of the Atmakaraka and Amatyakaraka in the Navamsha chart.
    *   **D9 (Navamsha):** `NavamshaLordsTabView` displays the lords of the Navamsha signs for each planet. The Navamsha is a divisional chart that gives more information about the second half of life and marriage.
    *   **D7 (Saptamsha):** `SaptamshaLordsTabView` shows the lords of the Saptamsha signs, a divisional chart related to children and creativity.
    *   **Lagnas:** `LagnasTabView` calculates special ascendants like Ghatika Lagna, Hora Lagna, and Indu Lagna.
    *   **64/22:** `SixtyFourTwentyTwoTabView` calculates the 64th Navamsha and 22nd Drekkana, which are considered sensitive points in the chart.
    *   **Pushkara:** `PushkaraTabView` identifies planets in Pushkara Navamsha, which are considered auspicious.

4.  **Data Persistence:** The app uses Core Data to store some user data, although the primary focus is on calculations rather than storing a large amount of user-generated content. The `PersistenceController` manages the Core Data stack. The `NotesModel.xcdatamodeld` defines the data model, which seems to be a remnant of a previous "Notes" app, as it includes entities like `HydrationEntry` and `UserSettings` related to water intake. This suggests the astrology features were built on top of a different app template.

5.  **UI and Theming:** The app uses custom UI styles defined in `UIStyles.swift` and a theme from `Theme.swift`. It has a clean, modern look with custom "PlanetChip" and "TagBadge" views. The UI is responsive to light and dark modes.

## Code Structure

*   **`NotesAppApp.swift`:** The main entry point of the app.
*   **`ContentView.swift`:** The main view, handling birth data input and hosting the tab view.
*   **`PlanetaryCalculator.swift`:** The core calculation engine.
*   **`SwissEphBridge.h` & `SwissEphWrapper.m`:** The bridge to the C-based Swiss Ephemeris library.
*   **`*TabView.swift` & `*View.swift` files:** Each astrological feature has a dedicated TabView and often a corresponding View to display the data. For example, `DashaTabView` and `DashaView`.
*   **`*Calc.swift` & `*Utils.swift` files:** These files contain the logic for specific astrological calculations (e.g., `JaiminiKarakasCalc.swift`, `DrekkanaUtils.swift`).
*   **`UIStyles.swift` & `Theme.swift`:** These files define the visual appearance of the app.
*   **Core Data related files:** `PersistenceController.swift`, `NotesModel.xcdatamodeld`.
*   **Helper files:** `LocationSearchManager.swift`, `NotificationManager.swift`, `Toast.swift`, etc.

## How it Works (Step-by-Step)

1.  The user opens the app and is presented with the `ContentView`.
2.  The user enters their date, time, and place of birth. The `LocationSearchManager` helps them find the correct location and its coordinates.
3.  When the user taps the "Create" button, the `recomputePlanets()` function in `ContentView` is called.
4.  This function calls the `compute()` method in the `PlanetaryCalculator`.
5.  The `PlanetaryCalculator` sets up the Swiss Ephemeris library, converts the birth date/time to Julian Day, and then calls the Swiss Ephemeris functions (through the Objective-C bridge) to get the sidereal longitude of each planet.
6.  The calculator also computes the Ascendant and house cusps.
7.  The results (an array of `PlanetPosition` objects) are returned to the `ContentView` and stored in the `@State` variable `planetPositions`.
8.  The `ContentView` passes the `planetPositions` and other birth data to the various `*TabView`s.
9.  Each `*TabView` then uses its corresponding `*Calc` or `*Utils` file to perform its specific calculations and display the results in a user-friendly format.
10. The user can swipe between the different tabs to view all the calculated astrological data.

In summary, this is a sophisticated Vedic Astrology app that leverages the power of the Swiss Ephemeris library to provide a wide range of detailed and accurate astrological calculations. The SwiftUI interface is well-structured and provides a clean and modern user experience.
