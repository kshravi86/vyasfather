# Vedic Light (Vyasfather) – Comprehensive Documentation

This document explains how the astrology engine, SwiftUI client, build tooling, and deployment automations in this repository fit together. It is intended for engineers who need to understand, extend, or operate the Vedic Light / Vyasfather app.

---

## 1. Product Overview

| Aspect | Details |
| --- | --- |
| App name | **Vedic Light** (Xcode target `NotesApp`) |
| Platforms | iOS / iPadOS, SwiftUI-only UI |
| Core value | Accurate Vedic astrology insights driven by Swiss Ephemeris data, presented in themed dashboards and tabs |
| Primary inputs | Birth date, time, and geolocation (lat/long derived via MapKit autocompletion) |
| Outputs | Planetary positions, divisional charts, dasha timelines, yogi points, Panchanga, special lagnas, deity recommendations, auspicious flags |

The main user journey is: enter birth details → the engine computes planetary/auxiliary data → tabbed dashboards render each slice of insight (Dasha, Yogi, Jaimini, Panchanga, divisional charts, etc.) with contextual copy and badges.

---

## 2. UI & Feature Surface

`NotesApp/ContentView.swift` orchestrates all presentation. Users land on the **Birth** tab (input form), then swipe across:

1. **Birth** (`BirthInfoView.swift`): capture DOB, TOB, place (with `LocationSearchManager`), compute planets via `PlanetaryCalculator`.
2. **Dasha** (`DashaTabView.swift`, `DashaView.swift`): Vimshottari dasha hierarchy.
3. **Yogi** (`YogiTabView.swift`, `YogiView.swift`): Yogi/Sahayogi/Avayogi points.
4. **Uttama** (`UttamaTabView.swift` + `UttamaCalc` helpers): favorable Drekkana checks.
5. **Jaimini** (`JaiminiTabView.swift`, `JaiminiKarakas.swift`, `JaiminiArudha.swift`): Chara Karakas and Arudha padas.
6. **Panchanga** (`PanchangaTabView.swift`, `PanchangaCalc.swift`): Tithi, Vara, Nakshatra, Yoga, Karana.
7. **Ishta** (`IshtaDevataTabView.swift`, `IshtaDevataCalc.swift`): deity guidance.
8. **D9 / Navamsha** (`NavamshaLordsTabView.swift`, `VargaCalculatorIOS.swift`).
9. **D7 / Saptamsha** (`SaptamshaLordsTabView.swift`).
10. **Special Lagnas** (`LagnasTabView.swift`, `SpecialLagnasCalc.swift`).
11. **64/22 Sensitive Points** (`SixtyFourTwentyTwoTabView.swift`, `SixtyFourTwentyTwoCalc.swift`).
12. **Pushkara** (`PushkaraTabView.swift`, `PushkaraUtils.swift`).

`DashboardSummaryBuilder.swift` builds the hero metrics shown above the tabs (sync status, birthplace description, etc.) and is unit tested in `NotesAppTests/DashboardSummaryBuilderTests.swift`.

---

## 3. Repository Layout

| Path | Purpose |
| --- | --- |
| `NotesApp/` | SwiftUI views, calculators, services, Core Data stack, Swiss ephemeris bridge, theming. |
| `NotesAppTests/` & `NotesAppUITests/` | Unit/UI tests (see §10). |
| `ThirdParty/SwissEph/` | Vendor source, objects, and `lib/` output (`libswe.a`) for the Swiss Ephemeris C library. |
| `fastlane/` & `Snapfile` | Fastlane lanes (screenshots) plus UI-test driven screenshot config. |
| `scripts/` | Helper C/Swift/Python scripts for CI validation, icon generation, and screenshots. |
| `.github/workflows/` | GitHub Actions definitions (CI, IPA builds, screenshot jobs per feature tab). |
| `docs/` | Human-readable documentation (this file plus supporting guides referenced below). |

Supporting Markdown references at the repo root (e.g., `AstrologyCalculations.md`, `CalculationLogicExplanation.md`, `GitHubActionsFlow.md`) provide deep dives on individual areas; this document links back to them where useful.

---

## 4. Architecture & Data Flow

```
User Input (Birth tab) 
   → Location search (MapKit/CLGeocoder)
   → PlanetaryCalculator.compute()
        ↳ SwissEphWrapper.m (Objective-C bridge)
            ↳ Swiss Ephemeris C library + .se1 data
   → Derived calculators (Dasha, Panchanga, Jaimini, etc.)
   → Tab view renderers + dashboard summary builder
   → Optional persistence (Core Data) + notifications
```

### Layering

1. **Presentation Layer (SwiftUI)**  
   Files: `ContentView.swift`, `*TabView.swift`, `MainTabView.swift`, `UIStyles.swift`, `Theme.swift`. Renders computed models and handles user input/toast feedback.

2. **Domain / Calculation Layer**  
   Files: `PlanetaryCalculator.swift`, `VimshottariDashaCalculator.swift`, `YogiCalculator.swift`, `VargaCalculatorIOS.swift`, etc. Pure-Swift transformations from astronomical data to astrology-friendly models. See §6.

3. **Platform Services**  
   Files: `LocationSearchManager.swift` (MapKit/Combine), `SunriseCalcIOS.swift`, `NotificationManager.swift`, `ScreenshotMode.swift`, `PersistenceController.swift`.

4. **Infrastructure**  
   Files: `SwissEphWrapper.m`, `SwissEphBridge.h`, `ThirdParty/SwissEph/src`, `NotesApp/SwissEph/*.se1`, automation scripts, GitHub Actions, Fastlane.

---

## 5. Module Reference

| Module | Responsibility | Key Files |
| --- | --- | --- |
| Birth data capture | Gather, validate, and persist DOB/TOB/location plus trigger recomputation. | `BirthInfoView.swift`, `ContentView.swift`, `LocationSearchManager.swift`, `DashboardSummaryBuilder.swift` |
| Planetary positions | Convert birth metadata into sidereal positions, ascendant, houses. | `PlanetaryCalculator.swift`, `PlanetKind.swift`, `PlanetPosition` model |
| Divisional charts | Compute Navamsha/Saptamsha and related lords. | `VargaCalculatorIOS.swift`, `NavamshaLordsTabView.swift`, `SaptamshaLordsTabView.swift` |
| Timing systems | Determine Vimshottari hierarchy. | `VimshottariDashaCalculator.swift`, `DashaTabView.swift`, `DashaView.swift` |
| Auspiciousness metrics | Yogi/Avayogi, Uttama Drekkana, Pushkara, Ishta Devata, special lagnas. | `YogiCalculator.swift`, `UttamaTabView.swift`, `IshtaDevataCalc.swift`, `SpecialLagnasCalc.swift`, `PushkaraUtils.swift`, `SixtyFourTwentyTwoCalc.swift` |
| Panchanga | Daily five limbs at birth moment. | `PanchangaCalc.swift`, `PanchangaTabView.swift` |
| Theming & UX polish | Visual identity, cosmic background, toast notifications. | `CosmicBackgroundView.swift`, `UIStyles.swift`, `Toast.swift`, `CelebrationOverlay.swift` |
| Persistence & state | Optional Core Data storage, screenshot helper states, syncing cues. | `PersistenceController.swift`, `NotesModel.xcdatamodeld`, `ScreenshotMode.swift`, `SnapshotHelper.swift` |

### 5.1 Mermaid File/Logic Map

```mermaid
graph TD
    subgraph UI Layer
        CV[ContentView.swift\nTab orchestration]
        BIV[BirthInfoView.swift\nInput form]
        MTV[MainTabView.swift\nIcon row]
        DTV[DashaTabView.swift]
        YTV[YogiTabView.swift]
        PHTV[PanchangaTabView.swift]
        NAV[NavamshaLordsTabView.swift]
        SAP[SaptamshaLordsTabView.swift]
        LAG[LagnasTabView.swift]
        SFT[SixtyFourTwentyTwoTabView.swift]
        PUT[PushkaraTabView.swift]
        ISH[IshtaDevataTabView.swift]
        UIT[UttamaTabView.swift]
        JAM[JaiminiTabView.swift]
        CV -->|binds state| BIV
        CV --> MTV
        CV --> DTV
        CV --> YTV
        CV --> PHTV
        CV --> NAV
        CV --> SAP
        CV --> LAG
        CV --> SFT
        CV --> PUT
        CV --> ISH
        CV --> UIT
        CV --> JAM
    end

    subgraph Services
        LSM[LocationSearchManager.swift\nMapKit autocomplete]
        DSM[DashboardSummaryBuilder.swift\nHero cards]
        PC[PersistenceController.swift\nCore Data]
        NOTIF[NotificationManager.swift]
        SNAP[SnapshotHelper.swift\nScreenshot presets]
        THEME[UIStyles.swift / Theme.swift]
        COS[COSMICBACKGROUNdView.swift]
        TOAST[Toast.swift]
        BIV --> LSM
        CV --> DSM
        CV --> PC
        CV --> SNAP
        CV --> THEME
        CV --> COS
        CV --> TOAST
    end

    subgraph Calculators
        PLANET[PlanetaryCalculator.swift]
        DASHAC[VimshottariDashaCalculator.swift]
        PANCH[PanchangaCalc.swift]
        YOGI[YogiCalculator.swift]
        VARGA[VargaCalculatorIOS.swift]
        ISHTA[IshtaDevataCalc.swift]
        LAGNA[SpecialLagnasCalc.swift]
        SIXFOUR[SixtyFourTwentyTwoCalc.swift]
        PUSHK[PushkaraUtils.swift]
        JAIMK[JaiminiKarakas.swift]
        JAIMA[JaiminiArudha.swift]
        UTTAMA[UttamaCalc utils]
        PLANET --> DASHAC
        PLANET --> PANCH
        PLANET --> YOGI
        PLANET --> VARGA
        PLANET --> ISHTA
        PLANET --> LAGNA
        PLANET --> SIXFOUR
        PLANET --> PUSHK
        PLANET --> JAIMK
        PLANET --> JAIMA
        PLANET --> UTTAMA
    end

    subgraph Swiss Ephemeris Bridge
        BRIDGE[SwissEphBridge.h\nBridging header]
        WRAP[SwissEphWrapper.m\nObjective-C wrapper]
        DATA[NotesApp/SwissEph/*.se1\nEphemeris data]
        C_SRC[ThirdParty/SwissEph/src/*.c\nC library]
        PLANET --> WRAP
        WRAP --> BRIDGE
        WRAP --> DATA
        WRAP --> C_SRC
    end

    subgraph Tooling & CI
        FAST[fastlane/Fastfile & Snapfile]
        GA[.github/workflows/*.yml]
        SCRIPTS[scripts/*.swift|py|c]
        FAST --> GA
        GA --> SCRIPTS
        SCRIPTS --> C_SRC
    end

    subgraph Tests
        DBTEST[NotesAppTests/DashboardSummaryBuilderTests.swift]
        PKTEST[NotesAppTests/PlanetKindTests.swift]
        UITEST[NotesAppUITests/*]
        DBTEST --> DSM
        PKTEST --> PLANET
        UITEST --> UI Layer
    end

    LSM --> PLANET
    BIV --> PLANET
```

---

## 6. Astrological Calculations (Inputs → Outputs)

| Calculation | Description & Inputs | Output & Files |
| --- | --- | --- |
| Planetary longitudes | Interfaces with Swiss Ephemeris (`SwissEphWrapper.m`) using DOB/TOB/location/timezone to produce sidereal positions (Lahiri ayanamsa). | `[PlanetPosition]`, ascendant, twelve houses. Files: `PlanetaryCalculator.swift`, `SwissEphBridge.h`, `SwissEphWrapper.m`. See `CalculationLogicExplanation.md`. |
| Vimshottari Dasha | Uses Moon’s Nakshatra to derive Mahadasha start + nested sub-periods. | Hierarchical array of `DashaPeriod` used by `DashaView.swift`. File: `VimshottariDashaCalculator.swift`. |
| Panchanga | Calculates Tithi/Vara/Nakshatra/Yoga/Karana via Sun/Moon angular relationships. | `PanchangaSnapshot` displayed in `PanchangaTabView.swift`. Files: `PanchangaCalc.swift`, `karanas.txt`, `checkyogas.txt`. Detailed in `AstrologyCalculations.md`. |
| Yogi / Avayogi | Sums solar/lunar longitudes to find prosperity/obstruction points and duplicates. | `YogiResult` for `YogiTabView.swift`. File: `YogiCalculator.swift`. |
| Divisional charts | Splits zodiac into Navamsha/Saptamsha segments, maps planets to section lords. | Tabular lords grid. Files: `VargaCalculatorIOS.swift`, `NavamshaLordsTabView.swift`, `SaptamshaLordsTabView.swift`, `DrekkanaUtils.swift`. |
| Special Lagnas | Computes Hora, Ghatika, Indu, etc. using ascendant offsets and planetary strengths. | `SpecialLagna` entries powering `LagnasTabView.swift`. |
| Sensitive points (64/22) | Finds 64th Navamsha & 22nd Drekkana from Lagna/Moon. | `SixtyFourTwentyTwoTabView.swift`. |
| Pushkara Navamsha | Checks whether planets occupy auspicious Pushkara navamshas and surfaces legends. | `PushkaraUtils.swift`, `PushkaraTabView.swift`, `pushkar.txt`. |
| Ishta & Palana Devata | Maps Atmakaraka/Amatyakaraka positions to deity archetypes. | `IshtaDevataTabView.swift`, `IshtaDevataCalc.swift`, `IshtaDevataTabView.swift`. |
| Jaimini metrics | Sorts planets by degrees to assign karakas; computes Arudha padas. | `JaiminiKarakas.swift`, `JaiminiArudha.swift`, `JaiminiTabView.swift`. |

For diagrammatic references, see `AstrologyCalculations.md` (includes Mermaid flows) and `LagnasPageLogic.md` / `LagnasPageLogicDiagrams.md`.

---

## 7. Supporting Services & Assets

- **Swiss Ephemeris data**: `.se1` files live under `NotesApp/SwissEph/` and are bundled into the app. The CI `Ensure SwissEph data bundled` step double-checks packaging.
- **Objective-C bridge**: `NotesApp/SwissEphBridge.h` + `NotesApp/SwissEphWrapper.m` expose `PlanetaryCalculator`-friendly APIs.
- **Location search**: `LocationSearchManager.swift` wraps `MKLocalSearchCompleter` and `MKLocalSearch` to provide type-ahead results and lat/long.
- **Persistence**: `NotesModel.xcdatamodeld` defines `UserSettings`. `PersistenceController.swift` initializes the Core Data stack (currently light usage).
- **Notifications**: `NotificationManager.swift` registers local notifications (used by hydration/history legacy parts).
- **Snapshot tooling**: `ScreenshotMode.swift` and `SnapshotHelper.swift` freeze UI states for deterministic screenshot capture. `scripts/resize_*.py` resize iPad imagery and `iOS-Screenshots-5/` stores generated assets.
- **App icons**: Generated during CI by `scripts/generate_app_icon.swift`.

---

## 8. Build & Run Guidance

1. **Prerequisites**
   - macOS with the latest Xcode (15.x recommended); iOS 17 simulator installed.
   - Ruby + Bundler for Fastlane tasks.
   - Homebrew `swiftformat`/`swiftlint` are optional; not enforced in CI.

2. **Clone & Install Ruby tooling**
   ```bash
   git clone https://github.com/kshravi86/vyasfather.git
   cd vyasfather
   gem install bundler           # once per machine
   bundle install                # installs Fastlane per Gemfile
   ```

3. **Open and run**
   - Launch `NotesApp.xcodeproj`.
   - Select the `NotesApp` scheme and an iPhone/iPad simulator.
   - Hit ⌘R. `ContentView` seeds a Bengaluru chart so the dashboard does not render empty states before the first compute.

4. **Command-line build/test**
   ```bash
   xcodebuild \
     -project NotesApp.xcodeproj \
     -scheme NotesApp \
     -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5' \
     build
   ```

5. **Regenerating Swiss Ephemeris**
   - CI compiles `ThirdParty/SwissEph/src/*.c` into `lib/libswe.a`. Locally, you can replicate with the shell fragment inside `.github/workflows/ios-appstore-upload-v3.yml` (or wrap it in a script if desired).

6. **Icons & screenshots**
   - `swift scripts/generate_app_icon.swift` creates the current gradient star set.
   - `bundle exec fastlane screenshots` triggers `snapshot` per `Snapfile`.

---

## 9. Tooling & Automation

- **Fastlane (`fastlane/Fastfile`)**
  - `screenshots` lane runs `snapshot` using the `Snapfile` (currently configured for the iPad Pro 13" M4 simulator and `en-US` locale).
  - Extend by adding lanes for `beta` or `release` as deployment automation matures (see `FastlaneExplanation.md`).

- **GitHub Actions (`.github/workflows/`)**
  - `ios-appstore-upload-v3.yml` / `ios-build-ipa.yml`: produce unsigned archives, inject Swiss ephemeris data, then export a signed IPA using secrets (`IOS_TEAM_ID`, `P12_BASE64`, `P12_PASSWORD`, `PROVISIONING_PROFILE_BASE64`). Detailed walkthrough in `GitHubActionsFlow.md`.
  - `ios-tests.yml`: runs `xcodebuild test` on macOS 14 with simulator 17.5. The workflow references `scripts/build_swiss.sh`; ensure that script exists or inline the build commands before enabling the job.
  - Several `working-*.yml` files capture per-tab screenshot runs (useful for marketing materials).

- **Scripts (`scripts/`)**
  - `ci_validate_swiss.c`: host-side validation of Swiss ephemeris calculations (run in CI with `continue-on-error` to avoid build failures on small discrepancies).
  - `generate_app_icon.swift`: programmatically renders layered gradients/symbols for app icons.
  - `resize_2778x1284*.py`: Pillow-based utilities to crop or letterbox screenshot canvases.

---

## 10. Testing & Quality

- **Unit tests** live in `NotesAppTests/`.
  - `DashboardSummaryBuilderTests.swift`: validates the hero info builder (location formatting, hero line fallbacks, sync badge copy).
  - `PlanetKindTests.swift`: checks the enum aliasing, icon metadata, and style fallbacks.
  - Run via `⌘U` in Xcode or `xcodebuild test` (see §8).

- **UI tests**: `NotesAppUITests/` currently contains stubs; expand these to lock down tab rendering before relying on Fastlane snapshot automation.

- **CI coverage**: `ios-tests.yml` ensures tests run on each push/PR once the Swiss build helper exists. Until then, run tests locally or trigger manual workflows.

- **Suggested additions**
  1. Add regression tests for each calculator (especially `VimshottariDashaCalculator` and `PanchangaCalc`).
  2. Create snapshot/UI tests that navigate each tab with fixed mock data to prevent layout regressions.

### Linting & Legacy Helper Guardrails

- **SwiftLint baseline**: `.swiftlint.yml` opts into whitespace/alignment rules that keep SwiftUI layout code tidy (`collection_alignment`, `vertical_parameter_alignment_on_call`, etc.) while excluding generated Swiss Ephemeris sources. Run `scripts/swiftlint.sh` (wraps `swiftlint lint --strict`) locally or wire it into an Xcode Run Script phase so issues show up beside the code that introduced them.
- **Hydration helpers**: The leftover hydration UI relies on `HydrationSettingsStore` inside `NotesApp/HydrationHelpers.swift`. The store now enforces default cup sizes, validates custom arrays via a JSON codec, and surfaces Core Data failures via `HydrationLogError`. Reuse those helpers if you extend or sunset the hydration feature to avoid duplicating persistence boilerplate.
- **Error handling**: `logDrink` is now `throws` and purges failed Core Data inserts to keep the store clean. UI call sites should `do/try/catch` and provide user feedback (see `TodayView.addDrink` for a reference implementation).

---

## 11. Deployment & Distribution

1. **Code signing assets**
   - Certificates (`apple_dist.p12`, `distribution.p12`), keys (`apple_dist.key`), CSR (`apple_dist.csr`), and provisioning profiles (`provisionprofilevediclightnew.mobileprovision`) are stored in the repo (encrypt before sharing).
   - Secrets referenced by CI: `IOS_TEAM_ID`, `APP_STORE_CONNECT_API_KEY`, `P12_BASE64`, `P12_PASSWORD`, `PROVISIONING_PROFILE_BASE64`. See `GitHubActionsSecrets.md` and `CurrentSecretsExplained.md`.

2. **CI IPA workflow**
   - Trigger `ios-appstore-upload-v3.yml` (`workflow_dispatch`) with `export_method` set to `app-store`, `ad-hoc`, etc.
   - The job: checkout → set up Xcode → build Swiss ephemeris → archive (`CODE_SIGNING_ALLOWED=NO`) → ensure Swiss data present → generate `ExportOptions.plist` → export signed IPA → upload artifact.
   - For true App Store submissions, consider enabling code signing during the archive step (not just export) to match Apple's recommended path.

3. **Manual deployment**
   - Archive inside Xcode (`Product > Archive`), then distribute via the Organizer using the same provisioning profile used in CI. If Swiss data is missing from the archive, drag-drop the `.se1` files into the `NotesApp` target's Copy Resources phase.

4. **Screenshots & marketing**
   - Dedicated workflows (`working-*.yml`, `ipad-screenshots.yml`, etc.) spin up simulator runs for each tab with deterministic birth data to populate App Store Connect assets (`iOS-Screenshots-5/`).

---

## 12. Configuration & Secrets

- `.working.yml` and `.working.yml.swp` contain current config experiments; do not delete.
- Application secrets (if any) belong under Xcode build settings or `.xcconfig` files (not yet present). Until then, keep environment-specific data inside GitHub secrets or local `.env` files ignored by Git.
- Files like `CurrentSecretsExplained.md`, `GitHubActionsSecrets.md`, and `AppleCodeSigningExplained.md` document the relationship between Apple Developer accounts, GitHub secrets, and Fastlane access.
- Swiss Ephemeris data is licensed; do not expose `.se1` files publicly without verifying redistribution terms.

---

## 13. Extending the App

1. **Adding a new calculation**
   - Create a pure Swift calculator (`*Calc.swift`) that accepts `planetPositions`, `ascendant`, and any derived state.
   - Write a focused SwiftUI tab (`NewThingTabView.swift`) and, if needed, supporting display components in `Views/`.
   - Register tab metadata inside `ContentView.tabsMeta` and insert the view inside the `TabView`.
   - Unit test the calculator (prefer deterministic planet fixtures) and add snapshot/UI coverage for the tab.

2. **Integrating additional data sources**
   - Keep Swiss Ephemeris bridging isolated; for experimental APIs (e.g., timezone lookup), wrap them in new service types to avoid polluting calculators with networking code.

3. **Theming & localization**
   - Colors and typography live in `Theme.swift`/`UIStyles.swift`. Add SwiftUI `LocalizedStringKey` wrappers before introducing new copy.

4. **Performance tips**
   - Calculators are invoked whenever DOB/TOB/location change (see `ContentView.recomputeInput`). Keep them deterministic and side-effect free; expensive computations should be cached inside `PlanetaryCalculator`.

---

## 14. Reference Materials

- `AppExplanation.md`: narrative overview of every tab.
- `CalculationLogicExplanation.md`: detailed breakdown of each calculator’s math.
- `AstrologyCalculations.md`: visual flow diagrams for planetary → derived data.
- `GitHubActionsFlow.md`: step-by-step IPA workflow explanation.
- `FastlaneExplanation.md`, `DependencyManagement.md`, `GitHubActionsSecrets.md`, `AppleCodeSigningExplained.md`, `WorkflowDiagrams.md`: operational guides.
- `LagnasPageLogic*.md`, `SwiftFileExplanations.md`, `LagnasPageLogicDiagrams.md`: tab-specific pseudo code and design references.

Use this document as your entry point, then dive into the specialized files above when you need deeper context.
