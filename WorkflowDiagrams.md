# Project Workflow Diagrams

This file contains diagrams illustrating the various calculation and deployment workflows in the project.

## Overall Calculation Flow

This diagram shows the end-to-end flow from user input to the final astrological calculations.

```mermaid
graph TD
    subgraph "Input"
        A["User enters Birth Details: Date, Time, Location"]
    end
    subgraph "Core Astronomical Engine"
        B["SunriseCalcIOS"] --> C{"Sunrise/Sunset Times"}
        A --> D["SwissEphWrapper"]
        D --> E{"Precise Planetary Longitudes & Ascendant"}
    end
    subgraph "Planetary Data Processing"
        E --> F["PlanetaryCalculator"]
        F --> G{"Astrological Data: Planet Sign, Degree, Nakshatra"}
    end
    subgraph "Derived Astrological Calculations"
        G --> H["VimshottariDashaCalculator"]
        G --> I["SixtyFourTwentyTwoCalc"]
        G --> J["PanchangaCalc"]
        G --> K["IshtaDevataCalc"]
        G --> L["YogiCalculator"]
        G --> M["SpecialLagnasCalc"]
        G --> N["VargaCalculatorIOS"]
        G --> O["JaiminiArudha & JaiminiKarakas"]
    end
    subgraph "Output"
        H --> P["Dasha Periods"]
        I --> Q["Sensitive Points"]
        J --> R["Panchanga Details"]
        K --> S["Ishta Devata"]
        L --> T["Yogi Points"]
        M --> U["Special Lagnas"]
        N --> V["Divisional Charts"]
        O --> W["Jaimini Karakas & Arudhas"]
    end
    subgraph "UI Presentation"
        P & Q & R & S & T & U & V & W --> X["Display in various App Views"]
    end
```

## Vimshottari Dasha Calculation

This diagram illustrates how the Vimshottari Dasha periods are calculated from the Moon's position at birth.

```mermaid
graph TD
    A["Moon's Longitude at Birth"] --> B{"Find Moon's Nakshatra"};
    B --> C{"Determine Starting Dasha Lord & Balance Period"};
    C --> D["Calculate Sequence of Mahadashas"];
    D --> E["Proportionally calculate Antardashas within each Mahadasha"];
    E --> F["Proportionally calculate Pratyantardashas within each Antardasha"];
    F --> G["Output: Hierarchical Dasha Periods with start/end dates"];
```

## Panchanga Calculation

This diagram shows how the five limbs of the Vedic day (Panchanga) are calculated.

```mermaid
graph TD
    subgraph "Inputs"
        A["Sun Longitude"]
        B["Moon Longitude"]
        C["Day of Week"]
    end
    subgraph "Calculations"
        D{"Angular Distance between Sun & Moon"} --> E["Tithi"]
        E --> F["Karana (Half Tithi)"]
        G{"Sum of Sun & Moon Longitudes"} --> H["Yoga"]
        B --> I["Nakshatra"]
        C --> J["Vara"]
    end
    subgraph "Output"
        E & F & H & I & J --> K["Panchanga Details"]
    end
```

## CI/CD Secrets Workflow

This diagram shows how secrets are securely used in the GitHub Actions deployment workflow.

```mermaid
graph TD
    subgraph "GitHub Secure Storage"
        A["GitHub Repository Secrets"]
        A -- "Encrypted Values" --> B(("Workflow Job"))
    end
    subgraph "GitHub Actions Runner (macOS)"
        B -- "Injects secrets into environment" --> C{"Workflow Steps"}
        C --> D["Step: Install Certificates"]
        C --> E["Step: Build & Sign App"]
        C --> F["Step: Upload to App Store"]
    end
```

## App Store Connect API Key Generation

This diagram explains how to generate the necessary API keys for uploading to the App Store.

```mermaid
graph TD
    A["Log in to App Store Connect"] --> B["Go to Users and Access"];
    B --> C["Select the Keys tab"];
    C --> D["Click 'Generate API Key' or select an existing one"];
    D --> E["Enter a name for the key and select 'Admin' role"];
    E --> F["Click 'Generate'"];
    F --> G["Download the .p8 private key file"];
    G --> H["Note the Issuer ID"];
    G --> I["Note the Key ID"];
    subgraph "Add to GitHub"
      H --> J["Add Issuer ID as a secret"];
      I --> K["Add Key ID as a secret"];
      G --> L["Add .p8 content as a secret"];
    end
```
