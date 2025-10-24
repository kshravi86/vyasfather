# Project Calculation Logic Documentation

## Overview
This document provides detailed explanations of the astrological calculation logic implemented in the project, primarily within the `NotesApp` directory. The project leverages the **Swiss Ephemeris** library for precise astronomical calculations, which form the foundation for all astrological derivations.

## Core Calculation Modules

### 1. Swiss Ephemeris Integration
*   **Astrological Concept:** The Swiss Ephemeris is a highly accurate astronomical library that provides planetary positions, house cusps, and other celestial data for any given date, time, and geographical location. It is fundamental for casting horoscopes and performing precise astrological calculations.
*   **Input:** Date, time, geographical coordinates (latitude, longitude), and time zone.
*   **Output:** Precise longitudes of planets (Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn, Rahu, Ketu, Uranus, Neptune, Pluto), house cusps, and other astronomical values.
*   **Methodology/Algorithm (High-Level):** The C-based Swiss Ephemeris library is integrated into the Swift codebase via an Objective-C wrapper (`SwissEphWrapper.m` and `SwissEphBridge.h`). Swift code calls methods in the wrapper, which in turn call the underlying Swiss Ephemeris functions to perform calculations. The library uses complex astronomical algorithms to account for various celestial phenomena.
*   **Relevant Files:** `NotesApp/SwissEphWrapper.m`, `NotesApp/SwissEphBridge.h`, `ThirdParty/SwissEph/src/*`

### 2. Planetary Calculations
*   **Astrological Concept:** Once raw planetary longitudes are obtained from the Swiss Ephemeris, they need to be interpreted in an astrological context, such as determining the sign, degree, and Nakshatra of each planet.
*   **Input:** Raw planetary longitudes (from Swiss Ephemeris).
*   **Output:** `[PlanetPosition]` objects, each containing the planet's name, longitude, sign, degree, minute, Nakshatra, and other derived astrological properties.
*   **Methodology/Algorithm (High-Level):** This module takes the raw longitudes and converts them into astrological positions. This involves mapping longitudes to the 12 zodiac signs (0-30 degrees per sign), determining the Nakshatra (27 lunar mansions), and potentially calculating other relevant attributes like planetary states (e.g., retrograde).
*   **Relevant File:** `NotesApp/PlanetaryCalculator.swift`

### 3. Vimshottari Dasha Calculation
*   **Astrological Concept:** Vimshottari Dasha is a widely used planetary period system in Vedic astrology. It divides a person's life into cycles ruled by different planets, indicating periods of influence and potential events. The system has sub-periods (Antardasha, Pratyantardasha, Sookshma, etc.) for finer predictions.
*   **Input:** Birth details (`BirthDetails` object including date, time, time zone, latitude, longitude), and the sidereal longitude of the Moon at birth.
*   **Output:** A hierarchical structure of Dasha periods (Mahadasha, Antardasha, Pratyantardasha, Sookshma), each with a ruling planet, start date, and end date.
*   **Methodology/Algorithm (High-Level):** The calculation starts with the Moon's Nakshatra at birth, which determines the starting Mahadasha planet and its remaining period. Subsequent Mahadashas follow a fixed sequence and duration. Antardashas, Pratyantardashas, and Sookshmas are calculated proportionally within their parent periods based on the same planetary sequence.
*   **Relevant File:** `NotesApp/VimshottariDashaCalculator.swift`

### 4. 64th Navamsha & 22nd Drekkana Calculation
*   **Astrological Concept:** These are sensitive points in a horoscope used to identify potential challenges, vulnerabilities, or critical life events. The 22nd Drekkana lord is the lord of the 22nd Drekkana from the ascendant or Moon. The 64th Navamsha lord is the lord of the 64th Navamsha from the ascendant or Moon.
*   **Input:** Ascendant (Lagna) details (sign, degree, minute) and planetary positions.
*   **Output:** The lords of the 22nd Drekkana and 64th Navamsha, calculated from both the Lagna and the Moon.
*   **Methodology/Algorithm (High-Level):**
    *   **Drekkana:** The zodiac is divided into 36 Drekkana (3.33 degrees each). The 22nd Drekkana is found by counting 21 Drekkana forward from the starting point (Lagna or Moon) and identifying the lord of the 22nd Drekkana.
    *   **Navamsha:** The zodiac is divided into 108 Navamsha (3.33 degrees each). The 64th Navamsha is found by counting 63 Navamsha forward from the starting point (Lagna or Moon) and identifying the lord of the 64th Navamsha.
*   **Relevant File:** `NotesApp/SixtyFourTwentyTwoCalc.swift`

### 5. Panchanga Calculation
*   **Astrological Concept:** Panchanga refers to the five limbs of the Vedic day: Tithi (lunar day), Vara (weekday), Nakshatra (lunar mansion), Yoga (astronomical combination), and Karana (half-Tithi). These elements are crucial for electional astrology (Muhurta) and understanding the daily energies.
*   **Input:** Date, time, and location.
*   **Output:** The Tithi, Vara, Nakshatra, Yoga, and Karana for the given moment.
*   **Methodology/Algorithm (High-Level):** The calculation involves precise astronomical positions of the Sun and Moon.
    *   **Tithi:** Based on the angular distance between the Sun and Moon.
    *   **Vara:** Simply the weekday.
    *   **Nakshatra:** Based on the Moon's longitude.
    *   **Yoga:** Based on the sum of the longitudes of the Sun and Moon.
    *   **Karana:** Half of a Tithi.
*   **Relevant File:** `NotesApp/PanchangaCalc.swift`

### 6. Ishta Devata Calculation
*   **Astrological Concept:** Ishta Devata is the chosen deity or guiding principle for an individual, believed to offer spiritual guidance and protection. Its determination often involves the Atmakaraka (soul significator) planet in Jaimini astrology.
*   **Input:** Planetary longitudes, specifically for determining the Atmakaraka.
*   **Output:** The Ishta Devata, typically associated with a specific deity or planetary influence.
*   **Methodology/Algorithm (High-Level):** The Atmakaraka is the planet with the highest degree in a sign (excluding Rahu/Ketu in some systems). The Ishta Devata is then derived from the Navamsha position of the Atmakaraka, or other specific rules related to the Atmakaraka.
*   **Relevant File:** `NotesApp/IshtaDevataCalc.swift`

### 7. Yogi, Avayogi, and Duplicate Yogi Calculation
*   **Astrological Concept:** These are specific points or planets in a horoscope that indicate auspiciousness (Yogi), inauspiciousness (Avayogi), and a supporting influence (Duplicate Yogi).
*   **Input:** Sun and Moon longitudes, and the Nakshatra of the Sun.
*   **Output:** The Yogi point, Yogi planet, Avayogi planet, and Duplicate Yogi planet.
*   **Methodology/Algorithm (High-Level):**
    *   **Yogi Point:** Calculated from the sum of the longitudes of the Sun and Moon, plus 93 degrees 20 minutes.
    *   **Yogi Planet:** The lord of the Nakshatra in which the Yogi point falls.
    *   **Avayogi Planet:** The lord of the Nakshatra that is the 9th from the Yogi Nakshatra.
    *   **Duplicate Yogi:** The planet that is the lord of the sign where the Yogi point falls.
*   **Relevant File:** `NotesApp/YogiCalculator.swift`

### 8. Special Lagnas Calculation
*   **Astrological Concept:** Besides the Ascendant (Lagna), Vedic astrology uses several other "special lagnas" or sensitive points that highlight specific areas of life or provide additional insights into a chart. Examples include Hora Lagna (wealth), Ghatika Lagna (power/authority), Bhava Lagna, etc.
*   **Input:** Birth details (date, time, location), planetary longitudes, and ascendant longitude.
*   **Output:** Longitudes and signs of various special lagnas.
*   **Methodology/Algorithm (High-Level):** Each special lagna has a specific calculation method, often involving the ascendant, planetary positions, or divisions of time. For instance, Hora Lagna involves dividing the ascendant sign into two halves.
*   **Relevant File:** `NotesApp/SpecialLagnasCalc.swift`

### 9. Varga (Divisional Chart) Calculation
*   **Astrological Concept:** Vargas, or divisional charts, are magnified sections of the main birth chart (Rashi chart). They are used to analyze specific areas of life in greater detail (e.g., Navamsha for marriage/dharma, Drekkana for siblings/courage, Saptamsha for children).
*   **Input:** Planetary longitudes and ascendant longitude.
*   **Output:** Planetary and ascendant positions in various divisional charts (e.g., D-9 Navamsha, D-3 Drekkana, D-7 Saptamsha).
*   **Methodology/Algorithm (High-Level):** Each Varga has a unique division scheme. For example, Navamsha (D-9) divides each sign into 9 parts, and the planet's position in the Navamsha is determined by which of these 9 parts it falls into. The calculation involves multiplying the planet's longitude within a sign by the Varga number and then mapping it to the corresponding sign in the divisional chart.
*   **Relevant File:** `NotesApp/VargaCalculatorIOS.swift`

### 10. Jaimini Astrology Calculations
*   **Astrological Concept:** Jaimini astrology is a distinct branch of Vedic astrology with its own set of principles, including the use of Karakas (significators) and Arudha Padas (manifested images).
    *   **Jaimini Karakas:** Planets become significators for specific aspects of life based on their degrees in a sign.
    *   **Arudha Padas:** These are "image" houses that show how a house or planet is perceived in the material world.
*   **Input:** Planetary longitudes.
*   **Output:**
    *   **Jaimini Karakas:** Atmakaraka, Amatyakaraka, Bhratrukaraka, Matrukaraka, Putrakaraka, Gnatikaraka, Darakaraka.
    *   **Arudha Padas:** Arudha Lagna, Dhana Arudha, etc.
*   **Methodology/Algorithm (High-Level):**
    *   **Karakas:** Determined by the highest to lowest degrees of planets in a sign (excluding Rahu/Ketu in some systems, or including them in others).
    *   **Arudha Padas:** Calculated by counting the number of signs from a house lord to its house, and then counting the same number of signs from the house lord again.
*   **Relevant Files:** `NotesApp/JaiminiArudha.swift`, `NotesApp/JaiminiKarakas.swift`

### 11. Utility Functions
*   **Astrological Concept:** These modules provide supporting calculations and data manipulations essential for the primary astrological computations.
*   **Input:** Varies by function (e.g., date objects, planetary longitudes, specific astrological parameters).
*   **Output:** Varies by function (e.g., formatted dates, specific astrological values like Drekkana lord, sunrise/sunset times).
*   **Methodology/Algorithm (High-Level):**
    *   `DrekkanaUtils.swift`: Contains logic for determining Drekkana lords or related calculations.
    *   `PushkaraUtils.swift`: Likely contains logic for identifying Pushkara Navamsha or Pushkara Bhaga, which are auspicious points.
    *   `SunriseCalcIOS.swift`: Calculates precise sunrise and sunset times for a given location and date, crucial for determining the start of an astrological day.
    *   `DateUtils.swift`: Provides helper functions for date and time manipulation, formatting, and conversions.
    *   `Int+Clamp.swift`: Utility for clamping integer values within a specific range.
*   **Relevant Files:** `NotesApp/DrekkanaUtils.swift`, `NotesApp/PushkaraUtils.swift`, `NotesApp/SunriseCalcIOS.swift`, `NotesApp/DateUtils.swift`, `NotesApp/Int+Clamp.swift`

## Overall Calculation Flow
1.  **Input Acquisition:** The application gathers birth details from the user: Date of Birth, Time of Birth, and Place of Birth (which is converted to Latitude, Longitude, and Time Zone).
2.  **Core Astronomical Data Generation:**
    *   `SunriseCalcIOS.swift` is used to determine local sunrise/sunset times, which can be critical for certain astrological calculations (e.g., determining the start of the astrological day).
    *   The `SwissEphWrapper.m` (interfacing with the Swiss Ephemeris library) is invoked to calculate the precise longitudes of all planets, the Ascendant (Lagna), and house cusps for the exact moment and location of birth.
3.  **Planetary Data Processing:**
    *   `PlanetaryCalculator.swift` takes the raw longitudes from Swiss Ephemeris and processes them into astrologically meaningful data points. This includes assigning each planet to its zodiac sign, calculating its degree within that sign, and identifying its Nakshatra.
4.  **Derived Astrological Calculations:** The processed planetary data, along with the birth details, are then fed into various specialized calculation modules to derive specific astrological insights:
    *   **Vimshottari Dasha:** `VimshottariDashaCalculator.swift` computes the planetary periods based on the Moon's Nakshatra.
    *   **Sensitive Points:** `SixtyFourTwentyTwoCalc.swift` identifies the 64th Navamsha and 22nd Drekkana lords.
    *   **Panchanga:** `PanchangaCalc.swift` determines the Tithi, Vara, Nakshatra, Yoga, and Karana.
    *   **Ishta Devata:** `IshtaDevataCalc.swift` calculates the personal deity based on planetary significators.
    *   **Yogi Points:** `YogiCalculator.swift` identifies the Yogi, Avayogi, and Duplicate Yogi.
    *   **Special Lagnas:** `SpecialLagnasCalc.swift` computes various secondary ascendants.
    *   **Divisional Charts (Vargas):** `VargaCalculatorIOS.swift` generates planetary positions for different divisional charts.
    *   **Jaimini Astrology:** `JaiminiArudha.swift` and `JaiminiKarakas.swift` perform Jaimini-specific calculations.
5.  **Output Presentation:** The results from these diverse calculations are then formatted and presented to the user through the application's various UI views (e.g., `DashaTabView`, `SixtyFourTwentyTwoTabView`, `LagnasTabView`, etc.), often utilizing utility functions for display formatting.
