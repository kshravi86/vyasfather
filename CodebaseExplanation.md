# Vedic Light iOS App: Codebase Explanation

This document provides a detailed explanation of the Vedic Light iOS app's codebase.

## 1. Project Overview

**Project Name:** The project is named "NotesApp" in Xcode, but the final app is distributed as "Vedic Light".

**Core Functionality:** Vedic Light is a comprehensive Vedic astrology application for iOS. It provides users with a wide range of astrological calculations and data, including:

*   **Planetary Positions:** Calculates the precise positions of the planets (Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn, Rahu, and Ketu) at the time of birth, using the Lahiri ayanamsa.
*   **Vimshottari Dasha:** Displays the Vimshottari Dasha system of planetary periods, including Mahadashas, Antardashas, and Pratyantardashas.
*   **Yogi and Avayogi:** Calculates the Yogi, Avayogi, and Sahayogi planets.
*   **Divisional Charts:** Calculates and displays the Navamsha (D9) and Saptamsha (D7) divisional charts.
*   **Jaimini Astrology:** Includes calculations for Jaimini Karakas and Arudha Padas.
*   **Panchanga:** Provides the five limbs of the Hindu calendar: Tithi, Vara (weekday), Nakshatra (lunar mansion), Yoga, and Karana.
*   **Special Lagnas:** Calculates various special ascendants, including Ghatika Lagna, Hora Lagna, and Indu Lagna.
*   **Other Calculations:** The app also calculates Ishta Devata, Palana Devata, Uttama Drekkana, 64th Navamsha, 22nd Drekkana, and Pushkara Navamsha.

## 2. Core Technologies

The app is built using a combination of modern and established Apple technologies:

*   **User Interface (UI):** The entire user interface is built with **SwiftUI**, Apple's modern, declarative UI framework. This allows for a reactive and easy-to-maintain UI.
*   **Astrology Engine:** The core astrological calculations are powered by the highly accurate **Swiss Ephemeris** library. This is a professional-grade ephemeris library used in many desktop astrology applications.
*   **Swift/Objective-C Interoperability:** To use the C-based Swiss Ephemeris library with Swift, the project utilizes an **Objective-C wrapper** (`SwissEphWrapper.m`) and a **bridging header** (`SwissEphBridge.h`). This allows the Swift code to call the necessary C functions from the Swiss Ephemeris library.
*   **Data Persistence:** The app uses **Core Data** to store user settings.
*   **Location Services:** **CoreLocation** and **MapKit** are used to obtain the user's location (latitude and longitude), which is essential for accurate astrological calculations.

## 3. Project Structure

The project is organized into the following main directories:

*   `NotesApp/`: This directory contains all the Swift source code for the application. Each major feature or calculation is encapsulated in its own set of Swift files.
*   `NotesApp.xcodeproj/`: This is the main Xcode project file that defines the project structure, build settings, and dependencies.
*   `ThirdParty/SwissEph/`: This directory contains the source code for the Swiss Ephemeris library, as well as a pre-compiled static library (`libswe.a`) that is linked into the final application.
*   `.github/workflows/`: This directory contains the GitHub Actions workflow file (`ios-build-ipa.yml`) for automating the build, signing, and distribution of the app.

## 4. Code Breakdown

### 4.1. SwiftUI Views

The UI is composed of a series of SwiftUI views, each responsible for a specific part of the user interface. The main views are:

*   `ContentView.swift`: The main view of the app, which contains the tab view controller and the primary input form for birth details.
*   `DashaTabView.swift`, `YogiTabView.swift`, `JaiminiTabView.swift`, etc.: Each of these files defines a tab in the main tab view, displaying a specific set of astrological data.
*   `UIStyles.swift`: This file defines custom UI styles, such as `PlanetChip` and `TagBadge`, to ensure a consistent look and feel throughout the app.

### 42. Astrological Calculation Logic

The astrological calculations are handled by a set of Swift files that wrap the Swiss Ephemeris library:

*   `PlanetaryCalculator.swift`: This is the main class that interacts with the Swiss Ephemeris library to calculate planetary positions, ascendant, and houses.
*   `VimshottariDashaCalculator.swift`: Calculates the Vimshottari Dasha periods.
*   `YogiCalculator.swift`: Calculates the Yogi and Avayogi points.
*   `JaiminiKarakas.swift` and `JaiminiArudha.swift`: Calculate Jaimini-specific astrological data.
*   `PanchangaCalc.swift`: Calculates the Panchanga.
*   `IshtaDevataCalc.swift`: Calculates the Ishta Devata and Palana Devata.
*   `VargaCalculatorIOS.swift`: Calculates the Navamsha (D9) and Saptamsha (D7) divisional charts.
*   `SpecialLagnasCalc.swift`: Calculates the special Lagnas.
*   `SixtyFourTwentyTwoCalc.swift`: Calculates the 64th Navamsha and 22nd Drekkana.
*   `PushkaraUtils.swift`: Calculates Pushkara Navamsha.
*   `DrekkanaUtils.swift`: Contains utility functions for Drekkana calculations.
*   `SunriseCalcIOS.swift`: Calculates sunrise and sunset times.

### 4.3. Swiss Ephemeris Integration

The integration with the Swiss Ephemeris library is handled by the following files:

*   `SwissEphBridge.h`: This bridging header exposes the C functions from the Swiss Ephemeris library to the Swift code.
*   `SwissEphWrapper.m`: This Objective-C wrapper provides a thin layer of abstraction over the C functions, making them easier to call from Swift.

### 4.4. Data Persistence

*   `PersistenceController.swift`: This file sets up the Core Data stack for the application.
*   `NotesModel.xcdatamodeld`: This is the Core Data model file that defines the `UserSettings` entity.

### 4.5. Continuous Integration (CI)

The `.github/workflows/ios-build-ipa.yml` file defines a GitHub Actions workflow that automates the process of building and distributing the app. The workflow performs the following steps:

1.  **Checkout Code:** Checks out the latest version of the code from the repository.
2.  **Set up Xcode:** Configures the correct version of Xcode on the build runner.
3.  **Build Swiss Ephemeris:** Compiles the Swiss Ephemeris C code into a static library (`libswe.a`).
4.  **Sign and Build:** Imports the necessary signing certificates and provisioning profiles, and then builds and archives the app.
5.  **Export IPA:** Exports the archived app as an `.ipa` file, which can be uploaded to the App Store or distributed for testing.
6.  **Upload Artifact:** Uploads the generated `.ipa` file as a build artifact, so it can be downloaded and installed.

## 5. Conclusion

The Vedic Light iOS app is a well-structured and comprehensive astrology application that leverages the power of the Swiss Ephemeris library to provide accurate astrological calculations. The use of SwiftUI for the UI and GitHub Actions for CI/CD makes the project modern and easy to maintain.
