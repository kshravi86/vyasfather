# Swift File Explanations for Vedic Light iOS App

This document provides a detailed explanation of each Swift file within the `NotesApp` directory of the Vedic Light iOS application.

## Core Application Structure

### `NotesAppApp.swift`
This is the main entry point of the entire iOS application, marked with `@main`. It sets up the `PersistenceController` for Core Data and injects the managed object context into the SwiftUI environment. It also includes conditional logic to disable animations if the app is launched with a specific argument (`--disable-animations`), which is useful for UI testing and screenshot generation. The app's root view is `ContentView`.

### `ContentView.swift`
This is the main entry point and root view of the Vedic Light application. It manages the core application state, including user birth details (date, time, location), computed planetary positions, and any calculation errors. It orchestrates the display of various astrological calculation tabs (Dasha, Yogi, Jaimini, Panchanga, etc.) using a `TabView`. It also features a "Cosmic Dashboard" that provides a summary of key planetary insights and handles the recomputation of planetary positions whenever birth details change.

### `MainTabView.swift`
*(Explanation for MainTabView.swift is missing from the provided context. Assuming it handles the bottom tab bar navigation for the main content views.)*
This SwiftUI view likely manages the main tab bar navigation at the bottom of the application, allowing users to switch between different astrological calculation views. It takes the currently selected tab and a list of tab metadata to construct the interactive tab items.

## Astrological Calculation Logic

### `PlanetaryCalculator.swift`
This file defines the `PlanetaryCalculator` class, which is central to the application's astrological computations. It uses the Swiss Ephemeris library (via a C bridge) to calculate the sidereal ecliptic longitudes, signs, degrees, minutes, nakshatras, padas, and retrograde status for the Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Rahu, and Ketu. It also computes the Ascendant and Placidus house cusps. The class handles the setup of the ephemeris path, error logging, and provides diagnostic information.

### `VimshottariDashaCalculator.swift`
This file contains the core logic for calculating the Vimshottari Dasha system, a predictive technique in Vedic astrology. It defines the `VimshottariDashaCalculator` class, which provides static methods to compute Mahadashas (major periods), Antardashas (sub-periods), Pratyantardashas (sub-sub-periods), and Sookshma Dashas. The calculations are based on the Moon's sidereal longitude at birth and a predefined order and duration of planetary periods.

### `YogiCalculator.swift`
This file contains the core logic for calculating the Yogi, Sahayogi, and Avayogi points and their associated planets and nakshatras. The `YogiCalculator` struct provides static methods to compute these sensitive astrological points based on the Sun and Moon longitudes. It also includes helper functions for normalizing degrees, determining nakshatra and sign lords, and formatting degrees. The `YogiResult` struct encapsulates all the calculated information.

### `VargaCalculatorIOS.swift`
This file provides the core logic for calculating divisional charts (Vargas), specifically the Navamsha (D9) and Saptamsha (D7). The `VargaCalculatorIOS` enum contains static methods to map a planet's longitude to its corresponding sign index in the D9 and D7 charts. It also includes functions to compute the D9 and D7 ascendants and the positions of all planets within these divisional charts, along with their house placements relative to the divisional ascendant.

### `SpecialLagnasCalc.swift`
This file contains the logic for calculating various special Lagnas (ascendants) beyond the natal ascendant. The `SpecialLagnasCalc` enum provides static methods to compute Ghatika Lagna, Hora Lagna (both standard and Jaimini methods), and Indu Lagna. These calculations involve the Sun's position at sunrise, elapsed time, and specific astrological rules for each Lagna, often utilizing `SunriseCalcIOS` and `PlanetaryCalculator` for intermediate values.

### `SixtyFourTwentyTwoCalc.swift`
This file contains the core logic for calculating the 64th Navamsha and 22nd Drekkana. These are considered sensitive points in Vedic astrology, often associated with challenges or vulnerabilities. The `SixtyFourTwentyTwoCalcIOS` enum provides static methods to compute the signs, lords, and degree ranges for these points, both from the Lagna (Ascendant) and from the Moon, using various astrological rules for divisional charts and sign lords.

### `JaiminiKarakas.swift`
This file contains the logic for calculating the Chara Karakas (temporary significators) in Jaimini astrology. The `JaiminiKarakasCalc` enum provides a static method to compute these karakas based on the planets' degrees within their signs. Planets are ranked by their degrees (with a special rule for Rahu) to determine the Atmakaraka, Amatyakaraka, and so on. It can optionally include Rahu in the calculation and attempts to derive house placements if house cusps are provided.

### `JaiminiArudha.swift`
This file contains the logic for calculating Arudha Padas in Jaimini astrology. The `JaiminiArudhaCalc` enum provides a static method to compute the Arudha Pada for each of the 12 houses. The calculation involves determining the lord of each house, its position relative to the house, and then applying specific Jaimini rules (including exceptions for lords in the 1st, 4th, 7th, or 10th houses) to find the final Arudha Pada sign and house.

### `PanchangaCalc.swift`
*(Explanation for PanchangaCalc.swift is missing from the provided context. Assuming it performs the Panchanga calculations.)*
This file likely contains the core logic for calculating the Panchanga (Tithi, Vara, Nakshatra, Yoga, Karana) for a given date, time, and location. It would use planetary positions and astronomical algorithms to determine these five elements of the Hindu calendar.

### `IshtaDevataCalc.swift`
This file contains the core logic for determining the Ishta Devata (personal deity) and Palana Devata (guardian deity) based on Jaimini principles. The `IshtaDevataCalcIOS` enum provides a static method that first identifies the Atmakaraka and Amatyakaraka. It then analyzes their positions in the Navamsha (D9) chart, specifically the 12th house from the Atmakaraka and the 6th house from the Amatyakaraka, to identify the determining planets and their associated deities and spiritual suggestions.

## UI Views (Astrology Specific)

### `BirthInfoView.swift`
This SwiftUI view serves as the primary input form for the user's birth details. It allows users to enter their date of birth, time of birth, and search for their birth location using `LocationSearchManager`. It displays a summary of the selected location, latitude, and longitude. The view also provides a "hero message" that changes based on whether the astrological chart has been computed and handles displaying calculation errors or toasts. It uses custom styling for cards and a `WarningBanner` for error messages.

### `DashaTabView.swift`
This SwiftUI view acts as a container for `DashaView`, handling the initial data preparation for Vimshottari Dasha calculations. It takes the user's birth date, time, coordinate, and planetary positions. It determines the appropriate time zone (defaulting to Asia/Kolkata for India) and then uses `VimshottariDashaCalculator` to compute the Mahadashas. These calculated dashas are then passed to `DashaView` for display. It shows a loading state if Moon's position or coordinate is not yet available.

### `DashaView.swift`
This SwiftUI view is dedicated to presenting the Vimshottari Dasha system, which outlines planetary periods and sub-periods. It displays Mahadashas (major periods), Antardashas (sub-periods), Pratyantardashas (sub-sub-periods), and Sookshma Dashas. The view features an interactive, expandable list, allowing users to drill down into different dasha levels. It also highlights the currently active dasha periods and provides options to filter the display. Calculations are performed using `VimshottariDashaCalculator`.

### `YogiTabView.swift`
This SwiftUI view acts as a wrapper for `YogiView`, handling the initial data fetching for the Yogi, Sahayogi, and Avayogi calculations. It checks for the presence of Sun and Moon positions from `planetPositions` and, if available, passes them to `YogiCalculator` to compute the results, which are then displayed by `YogiView`. If the necessary planetary data is not yet available, it shows a loading state.

### `YogiView.swift`
This SwiftUI view is responsible for displaying the results of the Yogi, Sahayogi, and Avayogi calculations. It presents these three important astrological points in distinct, styled cards. The Yogi card highlights the Yogi planet and its degree, nakshatra, and sign. The Sahayogi card shows the Sahayogi planet, and the Avayogi card details the Avayogi planet and its associated information, including a special note if it's derived via the 6th house from the Yogi.

### `UttamaTabView.swift`
This SwiftUI view determines and displays whether the Ascendant and each planet are in "Uttama Drekkana," a favorable divisional position. It uses `DrekkanaUtils` to perform these checks. The view lists each planet and the Ascendant, showing its sign, degree, and whether it is in Uttama Drekkana, along with a description of the Uttama Drekkana range for clarity.

### `JaiminiTabView.swift`
This SwiftUI view presents Jaimini astrology concepts. It displays two main sections: Chara Karakas (temporary significators) and Arudha Padas (symbolic representations of houses). It uses `JaiminiKarakasCalc` and `JaiminiArudhaCalc` to perform the necessary calculations and presents the results in a clear, card-based layout. Helper functions are included to provide short codes for Karakas and Arudha Padas.

### `PanchangaTabView.swift`
This SwiftUI view displays the Panchanga, which consists of the five limbs of the Hindu calendar for the birth moment: Tithi (lunar day), Vara (weekday), Nakshatra (lunar mansion), Yoga (a specific planetary combination), and Karana (half a lunar day). It uses `PanchangaCalcIOS` for the calculations and presents each limb in a dedicated section card. It also includes logic to determine the appropriate time zone (defaulting to Asia/Kolkata for locations within India) and provides meanings for Tithi groups.

### `IshtaDevataTabView.swift`
This SwiftUI view calculates and displays the Ishta Devata (personal deity) and Palana Devata (guardian deity) based on the birth chart. It uses `IshtaDevataCalcIOS` for the core calculations, which involve analyzing the Atmakaraka and Amatyakaraka planets in the Navamsha (D9) chart. The view presents a detailed breakdown of the factors leading to the determination of these deities, along with suggestions, all within a card-based layout.

### `NavamshaLordsTabView.swift`
This file defines a SwiftUI view responsible for displaying the Navamsha (D9) chart's ascendant and the lords of the Navamsha signs for each planet. It utilizes `VargaCalculatorIOS` to compute the D9 chart and `PlanetStyle` for consistent UI theming. The view presents this information in a structured, readable format, highlighting the D9 Ascendant and detailing each planet's Navamsha sign and its ruling lord.

### `SaptamshaLordsTabView.swift`
This SwiftUI view is responsible for displaying the Saptamsha (D7) chart's ascendant and the lords of the Saptamsha signs for each planet. The D7 chart is primarily used for analyzing matters related to children and creativity. It utilizes `VargaCalculatorIOS` to compute the D7 chart and presents the information in a structured list, similar to the `NavamshaLordsTabView`.

### `LagnasTabView.swift`
This SwiftUI view calculates and displays various special Lagnas (ascendants) such as Ghatika Lagna, Hora Lagna (both standard and Jaimini methods), and Indu Lagna. These Lagnas are used for deeper astrological analysis, particularly concerning wealth, timing of events, and specific life areas. The view uses `SpecialLagnasCalc` and `PlanetaryCalculator` for computations and presents the results in a grid-based card layout, along with descriptive information for each Lagna.

### `SixtyFourTwentyTwoTabView.swift`
This SwiftUI view displays calculations related to the 64th Navamsha and 22nd Drekkana. These are considered sensitive points in a horoscope that can indicate challenges or vulnerabilities. The view presents the lords of these sensitive points, calculated both from the Lagna (Ascendant) and from the Moon, using the `SixtyFourTwentyTwoCalcIOS` utility.

### `PushkaraTabView.swift`
This SwiftUI view identifies and displays planets and the Lagna (Ascendant) that are in Pushkara Navamsha. Pushkara Navamshas are considered auspicious divisions in Vedic astrology, indicating strength and positive outcomes. It uses `PushkaraUtils` to evaluate each planet's position and the Lagna, presenting only those that fall within a Pushkara Navamsha in a simple list format.

### `TodayView.swift`
This SwiftUI view is part of the hydration tracking feature. It displays the user's daily hydration progress against a set goal, visualized with a circular progress ring. Users can quickly log drinks using predefined sizes or through an "Add Drink" sheet. It integrates with Core Data to fetch and store hydration entries and `UserSettings`. The view also triggers a `CelebrationOverlay` when the daily goal is met and schedules notifications. *Note: This functionality seems unrelated to the core Vedic astrology purpose of the app.*

### `HistoryView.swift`
This SwiftUI view displays a list of past hydration entries, ordered from newest to oldest. It uses Core Data to fetch `HydrationEntry` objects and presents each entry with its amount, drink type, caffeine content (if applicable), and timestamp. Users can also delete entries from the list. *Note: This is part of the hydration tracking feature, which seems unrelated to the core Vedic astrology purpose.*

### `NoteDetailView.swift`
This SwiftUI view is a placeholder that indicates it is "no longer used" and directs users to the "Today tab to log drinks." This strongly suggests that it was part of an older "Notes" or "Hydration" feature that has been deprecated or refactored, further supporting the idea that the current astrology app was built on top of a different project template.

### `NotesListView.swift`
This SwiftUI view is a simple wrapper that directly presents the `HistoryView`. Given the context of the project evolving from a "NotesApp" to a "Vedic Light" astrology app, and the presence of hydration-related features, it's likely that this view was originally intended for a list of notes but now serves as an entry point to the hydration history.

### `SettingsView.swift`
This SwiftUI view allows users to configure various settings, primarily related to the hydration tracking feature. Users can input their weight, select an activity level, and customize quick-add cup sizes. The view calculates a suggested daily hydration goal and allows users to apply it. It interacts with `UserSettings` via `SettingsProvider` and `CoreData` for persistence. It also includes sections for privacy policy, support website, and email support links. *Note: This functionality seems unrelated to the core Vedic astrology purpose of the app.*

### `DiagnosticsView.swift`
This SwiftUI view provides diagnostic information about the application's internal state, particularly concerning the Swiss Ephemeris library. It displays the path to the ephemeris files, the count of files found, and samples of these files. It also shows a log of recent operations and errors from the `PlanetaryCalculator`. The view includes functionality to copy the diagnostic logs to the clipboard for easy sharing and debugging.

## Utility and Helper Files

### `LocationSearchManager.swift`
This file defines the `LocationSearchManager` class, an `ObservableObject` responsible for handling location search functionality using Apple's MapKit. It utilizes `MKLocalSearchCompleter` to provide real-time search suggestions as the user types and `MKLocalSearch` to resolve a selected suggestion into a full `MKPlacemark` (including coordinates, state, and country). The manager includes debouncing for search queries and initially focuses searches within India, expanding to the world if no results are found.

### `SunriseCalcIOS.swift`
This file provides utility functions for calculating sunrise and sunset times for a given date, latitude, longitude, and time zone. The `SunriseCalcIOS` enum contains static methods that implement an algorithm (adapted from NOAA Solar Calculator) to determine these solar events. It includes helper functions for normalizing degrees and time values.

### `DrekkanaUtils.swift`
This file provides utility functions for Drekkana calculations, specifically for determining "Uttama Drekkana." It defines `Modality` and `ZodiacSign` enums for astrological concepts. The `DrekkanaUtils` struct includes static methods to determine the modality of a zodiac sign (movable, fixed, or dual), normalize degrees, and calculate the degree within a sign. Its primary function, `isUttamaDrekkana`, checks if a given absolute degree falls within the auspicious Uttama Drekkana range based on the sign's modality, and `rangeDescription` provides a textual representation of these ranges.

### `PushkaraUtils.swift`
This file contains utility functions for evaluating whether a planet or the Lagna (Ascendant) is in a "Pushkara Navamsha." Pushkara Navamshas are specific auspicious degrees within signs that are considered beneficial. The `PushkaraUtils` enum provides static methods to determine the element of a sign, define the Pushkara windows (degree ranges) for each element, and then evaluate if a given planet's or Lagna's longitude falls within these auspicious ranges.

### `DateUtils.swift`
This file provides utility functions for formatting dates and durations. Specifically, `formatDateRange` formats a start and end date into a "MMM d, yyyy - MMM d, yyyy" string, and `formatDuration` calculates and formats the duration between two dates into a "Yy Mm Dd" string. These functions are used across various views to present date and time information consistently.

### `Int+Clamp.swift`
This file provides a simple extension to the `Int` type, adding a `clamped(to:)` method. This method allows an integer value to be constrained within a specified closed range, ensuring it does not go below the lower bound or above the upper bound of the range. This is a common utility for safely handling numerical values.

### `UIStyles.swift`
This file centralizes custom UI styling components and extensions used throughout the application. It defines a `CardBackground` `ViewModifier` for consistent card-like visual elements, and an extension on `View` to easily apply this modifier. It also includes `PlanetStyle` enum/struct which provides static methods to get specific colors and SF Symbols (icons) for planets, ensuring a unified visual theme. `PlanetChip` and `TagBadge` structs are custom SwiftUI views for displaying planet names with their icons and general tags, respectively.

### `Theme.swift`
This file defines the `CosmicTheme` enum, which centralizes the application's color palette and gradient styles. It provides static properties for consistent background, accent, text, and secondary text colors, as well as a `gradient` function that returns a `LinearGradient` suitable for the app's cosmic aesthetic, adapting to the current color scheme. This ensures a unified visual appearance across the application.

### `CosmicBackgroundView.swift`
This SwiftUI view creates the dynamic, animated cosmic background seen throughout the application. It uses a combination of `LinearGradient`, `AngularGradient`, and `Canvas` to render a visually rich, subtly moving starfield and nebula effect. The `TimelineView` is used to animate the stars' twinkling and the gradient's rotation, providing an immersive and aesthetically pleasing backdrop for the app's content.

### `Toast.swift`
This file defines a `Toast` struct, which is a simple data model for displaying temporary, non-intrusive messages to the user. It includes properties for a title, optional subtitle, and a system image. It also provides a `ToastView` SwiftUI component for rendering the toast and a `ToastPresenter` `ViewModifier` that handles the presentation logic (showing, animating, and dismissing) of toasts. An extension on `View` makes it easy to attach toast functionality to any view.

### `CelebrationOverlay.swift`
This SwiftUI view presents a celebratory overlay, typically shown when a user achieves a goal (e.g., hydration goal). It features a large "sparkles" icon, a "Goal Reached!" message, and a subtle confetti animation. The overlay animates in and out, providing positive visual feedback to the user. *Note: This is part of the hydration tracking feature, which seems unrelated to the core Vedic astrology purpose.*

### `ScreenshotMode.swift`
This file defines a simple `ScreenshotMode` enum with a static `isOn` property. This property checks for a specific launch argument (`--seed-screenshots`) to determine if the application is running in a mode intended for generating screenshots. This is typically used in UI testing or for automated screenshot generation tools like Fastlane Snapshot, allowing the app to adjust its behavior (e.g., pre-fill data, skip animations) for consistent screenshot capture.

### `SnapshotHelper.swift`
This file provides helper functions for UI testing and screenshot generation, primarily used with Fastlane Snapshot. It includes utilities for setting up the application for testing (language, locale, launch arguments), taking screenshots, and waiting for loading indicators to disappear. This is crucial for automating the process of generating localized screenshots for app store listings.

## Core Data and Notifications (Hydration Specific)

### `PersistenceController.swift`
This file defines the `PersistenceController` struct, which is responsible for setting up and managing the Core Data stack for the application. It provides a shared singleton instance for the main application and a separate `preview` instance for SwiftUI previews, pre-populated with sample data. The controller initializes an `NSPersistentContainer` named "NotesModel" and handles loading persistent stores, including an in-memory option for testing.

### `NotificationManager.swift`
This file defines the `NotificationManager` class, a singleton responsible for handling user notifications. It provides methods to request notification authorization and to schedule local notifications. Specifically, it schedules "inactivity reminders" if the user hasn't logged water for a while and "post-workout reminders" to encourage rehydration after exercise. *Note: This is part of the hydration tracking feature, which seems unrelated to the core Vedic astrology purpose.*

### `HydrationHelpers.swift`
This file contains utility functions and structures related to a hydration tracking feature, which appears to be a remnant from a previous app template. It includes `ActivityLevel` enum, `HydrationCalculator` for determining daily water goals, `SettingsProvider` for fetching and managing `UserSettings` (including cup sizes), and `HydrationStats` for calculating today's total water intake from `HydrationEntry` Core Data entities. It also contains `logDrink` function to record hydration events. *Note: This functionality seems unrelated to the core Vedic astrology purpose of the app.*
