# Vyasfather / Vedic Light - Engineering Handbook

This handbook consolidates everything needed to understand, build, extend, test, and ship the Vedic Light (a.k.a. Vyasfather) SwiftUI application. Treat it as the canonical reference for engineers onboarding to the codebase or planning cross-cutting changes.

---

## 0. Quick Facts

| Item | Details |
| --- | --- |
| Xcode target | `NotesApp` |
| Platforms | iOS and iPadOS (SwiftUI-only UI, iOS 17 baseline) |
| Languages | Swift 5.10, Objective-C (Swiss bridge), shell/Ruby for tooling |
| Core value prop | Turn Swiss Ephemeris astronomy data into themed Vedic astrology dashboards |
| Primary dependencies | Swiss Ephemeris (`ThirdParty/SwissEph`), MapKit/Combine, Core Data, Fastlane, GitHub Actions |

---

## 1. User Experience Overview

1. **Birth capture** - `BirthInfoView.swift` gathers date, time, place. `LocationSearchManager.swift` resolves geocoding via MapKit autocomplete.
2. **Computation** - `PlanetaryCalculator.swift` calls the Objective-C bridge (`SwissEphWrapper.m`, `SwissEphBridge.h`) backed by `ThirdParty/SwissEph`. The calculator produces sidereal positions, ascendant, houses, and sunrise data.
3. **Derived calculators** - Swift modules (Dasha, Panchanga, Pushkara, etc.) convert planetary data into domain models per feature tab.
4. **Dashboards** - `ContentView.swift`, `MainTabView.swift`, and `DashboardSummaryBuilder.swift` render hero metrics plus detail tabs for each astrology surface (Dasha, Jaimini, divisional charts, Panchanga, Yogi, Special Lagnas, 64/22, Pushkara, Ishta Devata, Uttama).
5. **Snapshot/screenshot modes** - `ScreenshotMode.swift` and `SnapshotHelper.swift` set deterministic mock data for CI screenshot runs and App Store artwork.

Each tab owns its own `*TabView.swift` file with supporting calculators nearby. This keeps SwiftUI presentation and domain logic close without mixing Apple framework APIs into pure calculation types.

---

## 2. Repository Layout

| Path | Description |
| --- | --- |
| `NotesApp/` | SwiftUI views, calculators, services, Core Data stack, Swiss bridge headers, `.se1` ephemeris data. |
| `NotesAppTests/` | Unit tests for calculators and dashboard helpers. |
| `NotesAppUITests/` | UI tests plus screenshot helpers that Fastlane lanes reuse. |
| `ThirdParty/SwissEph/` | Vendor Swiss Ephemeris source and `lib/libswe.a`. CI rebuilds this library. |
| `fastlane/` and `Snapfile` | Fastlane configuration (screenshots lane) and simulator targets. |
| `.github/workflows/` | CI/CD workflows covering IPA creation, Swiss builds, tests, and screenshot capture per tab. |
| `scripts/` | C/Swift/Python helpers (Swiss validation, icon generation, screenshot resizing). |
| `docs/` | Markdown guides (`ProjectDocumentation.md`, this handbook, feature-specific explainers). |
| Root Markdown | Deep dives: `AstrologyCalculations.md`, `CalculationLogicExplanation.md`, `GitHubActionsFlow.md`, `LagnasPageLogic*.md`, etc. |

---

## 3. Architecture and Data Flow

```
User input (Birth tab)
      |
LocationSearchManager (MapKit geocode, timezone)
      |
PlanetaryCalculator (SwissEphWrapper + ThirdParty/SwissEph)
      |
Domain calculators (Dasha, Panchanga, Jaimini, Varga, Pushkara, etc.)
      |
DashboardSummaryBuilder + SwiftUI tab views
      |
SnapshotHelper / ScreenshotMode (optional) for deterministic previews and CI screenshots
```

**Layering**

- **Presentation**: `ContentView.swift`, `MainTabView.swift`, `*TabView.swift`, `UIStyles.swift`, `Theme.swift`. Handles state, toast messaging (`Toast.swift`), and tab coordination.
- **Domain / Calculations**: Pure Swift structs and enums that transform a `ComputedChart` (from `PlanetaryCalculator`) into `DashaPeriod`, `PanchangaSnapshot`, `SpecialLagna`, `PushkaraResult`, and other models.
- **Services**: `LocationSearchManager.swift`, `SunriseCalcIOS.swift`, `NotificationManager.swift`, `PersistenceController.swift`, `HydrationHelpers.swift`, `ScreenshotMode.swift`.
- **Infrastructure**: `SwissEphBridge.h`, `SwissEphWrapper.m`, the Swiss data bundle, GitHub workflows, Fastlane, provisioning material.

---

## 4. Feature Modules

| Tab | UI entry point | Domain types | Notes |
| --- | --- | --- | --- |
| Birth | `BirthInfoView.swift` | `BirthDetails`, `PlanetaryCalculator` | Validates inputs, triggers recompute, surfaces location search results. |
| Dasha | `DashaTabView.swift`, `DashaView.swift` | `VimshottariDashaCalculator`, `DashaPeriod` | Shows Mahadasha/Antardasha/Paryantardasha stacks with timeline copy. |
| Yogi | `YogiTabView.swift`, `YogiView.swift` | `YogiCalculator`, `YogiResult` | Highlights Yogi, Sahayogi, Avayogi planets and duplicates. |
| Uttama Drekkana | `UttamaTabView.swift`, `UttamaCalc` helpers | `SixtyFourTwentyTwoCalc` (shared) | Flags favorable Drekkana placements. |
| Jaimini | `JaiminiTabView.swift` | `JaiminiKarakas`, `JaiminiArudha` | Ranks planets by degrees and maps Arudha padas. |
| Panchanga | `PanchangaTabView.swift` | `PanchangaCalc`, `PanchangaSnapshot` | Combines Tithi, Vara, Nakshatra, Yoga, Karana with icons. |
| Ishta / Palana Devata | `IshtaDevataTabView.swift` | `IshtaDevataCalc`, `DevataDescriptor` | Ties Atmakaraka and Amatyakaraka to deity archetypes. |
| Navamsha (D9) | `NavamshaLordsTabView.swift` | `VargaCalculatorIOS`, `NavamshaCell` | Tabular display of Navamsha lordships. |
| Saptamsha (D7) | `SaptamshaLordsTabView.swift` | `VargaCalculatorIOS` | Similar grid for D7 placements. |
| Special Lagnas | `LagnasTabView.swift` | `SpecialLagnasCalc`, `SpecialLagna` | Hora, Ghatika, Indu, Bhrigu, Adhi, and related metrics. |
| Sensitive Points | `SixtyFourTwentyTwoTabView.swift` | `SixtyFourTwentyTwoCalc` | 64th Navamsha and 22nd Drekkana alerts. |
| Pushkara | `PushkaraTabView.swift` | `PushkaraUtils`, `pushkar.txt` | Highlights Pushkara Navamsha occupancy and guidance. |

`DashboardSummaryBuilder.swift` augments each tab with hero metrics (sync badges, geo/time summary, sunrise, Moon nakshatra) and is covered by unit tests.

---

## 5. Calculation Engines

| Engine | Inputs | Outputs | Files |
| --- | --- | --- | --- |
| Planetary | Birth datetime, timezone, geo coordinates, Swiss data | Planet positions, ascendant, houses, sunrise | `PlanetaryCalculator.swift`, `SwissEphWrapper.m`, `SwissEphBridge.h`, `SunriseCalcIOS.swift` |
| Vimshottari Dasha | Moon nakshatra, planetary years table | Nested `DashaPeriod` values | `VimshottariDashaCalculator.swift`, `DateUtils.swift` |
| Panchanga | Sun/Moon angles, sunrise | `PanchangaSnapshot` (Tithi, Vara, Nakshatra, Yoga, Karana) | `PanchangaCalc.swift`, `karanas.txt`, `checkyogas.txt` |
| Varga | Planetary degrees | Divisional placements for D9 and D7 | `VargaCalculatorIOS.swift`, `NavamshaLordsTabView.swift`, `SaptamshaLordsTabView.swift` |
| Yogi / Avayogi | Solar and lunar longitudes | `YogiResult` | `YogiCalculator.swift`, `YogiView.swift` |
| Special Lagnas | Ascendant, house cusps, strength metrics | `SpecialLagna` array | `SpecialLagnasCalc.swift`, `LagnasTabView.swift` |
| Sensitive Points | Lagna and Moon degrees | `SixtyFourTwentyTwoSnapshot` | `SixtyFourTwentyTwoCalc.swift` |
| Pushkara | Planetary positions | `PushkaraResult`, textual hints | `PushkaraUtils.swift`, `pushkar.txt` |
| Ishta Devata | Atmakaraka, Navamsha placements | `IshtaDevataDescriptor` | `IshtaDevataCalc.swift`, `IshtaDevataTabView.swift` |
| Jaimini | Ordered planets, divisions | `JaiminiKarakas`, `ArudhaResult` | `JaiminiKarakas.swift`, `JaiminiArudha.swift` |

Shared helpers include `HydrationHelpers.swift`, `Int+Clamp.swift`, `DateUtils.swift`, `Theme.swift`, and `DashboardSummaryBuilder.swift`.

---

## 6. Services and Utilities

- **Location search** (`LocationSearchManager.swift`): Combine pipeline around `MKLocalSearchCompleter`. Produces `PlaceResult` objects consumed by `BirthInfoView`.
- **Persistence** (`PersistenceController.swift`, `NotesModel.xcdatamodeld`): Minimal Core Data store for cached birth info and settings.
- **Notifications** (`NotificationManager.swift`): Wraps `UNUserNotificationCenter` for hydration reminders; currently optional.
- **Snapshot and screenshot** (`ScreenshotMode.swift`, `SnapshotHelper.swift`, `NotesAppUITests/SnapshotHelper.swift`): Provide deterministic data for previews, UI tests, and Fastlane screenshot jobs.
- **Celebration overlays and toasts** (`CelebrationOverlay.swift`, `Toast.swift`): Provide feedback for saved charts, sync success, or screenshot completion.

---

## 7. Build, Run, and Configuration

1. **Prerequisites**: macOS with the latest Xcode (15.x recommended), Ruby plus Bundler, Swiss Ephemeris data already checked in under `NotesApp/SwissEph`.
2. **Setup**
   ```bash
   git clone https://github.com/kshravi86/vyasfather.git
   cd vyasfather
   gem install bundler
   bundle install
   open NotesApp.xcodeproj
   ```
3. **Run**: Select the `NotesApp` scheme, choose an iOS or iPadOS simulator (iPhone 15 Pro or iPad Pro 13" M4, matching `Snapfile`), then press `Command+R`. Default Bengaluru birth data renders all tabs immediately.
4. **Swiss Ephemeris rebuild**: Reuse the script block in `.github/workflows/ios-appstore-upload-v3.yml` to compile `ThirdParty/SwissEph/src/*.c` into `ThirdParty/SwissEph/lib/libswe.a` when refreshing vendors.
5. **Icons**: Generate via `swift scripts/generate_app_icon.swift` after editing icon sources.

Code signing and CI secret guides live in `AppleCodeSigningExplained.md`, `CurrentSecretsExplained.md`, `GitHubActionsSecrets.md`, and `GitHubSecretsGuide.md`.

---

## 8. Testing Strategy

| Layer | Command / location | Notes |
| --- | --- | --- |
| Unit tests | `NotesAppTests/` | `DashboardSummaryBuilderTests.swift` verifies summary formatting, `PlanetKindTests.swift` protects calculator classification logic. |
| UI tests | `NotesAppUITests/NotesAppUITests.swift` | Exercises tab navigation and screenshot toggles; extend with flows for onboarding and notifications. |
| Snapshot helpers | `NotesAppUITests/SnapshotHelper.swift` | Shared with Fastlane screenshot lane to capture deterministic UI states. |
| CLI | ```xcodebuild -project NotesApp.xcodeproj -scheme NotesApp -destination "platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5" test``` | Mirrors `.github/workflows/ios-tests.yml`. |

Fastlane screenshots run with `bundle exec fastlane screenshots`, enabling `ScreenshotMode` and saving PNGs to `iOS-Screenshots-5/`.

---

## 9. Automation and CI/CD

- **Fastlane** (`fastlane/Fastfile`, `Snapfile`): currently exposes a `screenshots` lane that boots the target simulator, runs the UITest navigator, and writes deterministic PNGs. Extend with `beta` or `release` lanes to automate TestFlight/App Store Connect submissions.
- **GitHub Actions** (`.github/workflows/*.yml`):
  - `ios-tests.yml` - runs `xcodebuild test` after compiling Swiss Ephemeris.
  - `ios-build-ipa.yml` - rebuilds Swiss, archives `NotesApp`, exports a signed IPA, and uploads artifacts.
  - `ios-appstore-upload-v3.yml` - full release flow (Swiss build, archive, export, App Store Connect upload).
  - `working-*.yml`, `ipad-*.yml` - deterministic simulator screenshot jobs per tab (Dasha, Panchanga, D9, Yogi, etc.) writing PNGs into `iOS-Screenshots-5/` or GitHub artifacts.
- **Scripts**:
  - `scripts/ci_validate_swiss.c` - ensures `libswe.a` matches expected Swiss build options.
  - `scripts/generate_app_icon.swift` - composes platform icon sets.
  - `scripts/resize_*.py` - resizes screenshot PNGs for App Store and marketing.

Populate GitHub secrets listed in `CurrentSecretsExplained.md` (`IOS_TEAM_ID`, `P12_*`, `PROVISIONING_PROFILE_BASE64`, etc.). Provisioning files (`distribution.p12`, `provisionprofilevediclightnew.mobileprovision`) and certificates remain in the repo for manual builds but should eventually move to secure storage.

---

## 10. Release Checklist

1. Confirm `NotesApp/SwissEph/*.se1` files and `ThirdParty/SwissEph/lib/libswe.a` exist and match the Swiss version pinned in CI.
2. Update marketing copy or static descriptions within each tab as needed and refresh `HydrationHelpers.swift` default data when models change.
3. Bump `CFBundleShortVersionString` and `CFBundleVersion` in `NotesApp/Info.plist`.
4. Run `xcodebuild test` locally plus `bundle exec fastlane screenshots` to refresh App Store imagery.
5. Archive the app via Xcode Organizer or the `xcodebuild archive` command used in `ios-build-ipa.yml`.
6. Upload the signed IPA through Fastlane deliver, Transporter, or the GitHub Action release workflow. Monitor App Store Connect processing and screenshot audits.

---

## 11. Extensibility Guidelines

1. **Adding a new calculator/tab**
   - Start with a pure Swift calculator (no SwiftUI) that consumes `ComputedChart`.
   - Create a companion `*TabView.swift` and models dedicated to the UI.
   - Inject calculator output in `ContentView` and `DashboardSummaryBuilder` for hero cards.
   - Seed deterministic data in `HydrationHelpers.swift` and `ScreenshotMode.swift`.
   - Add unit coverage in `NotesAppTests/` and update UITests plus Fastlane screenshot lists.
2. **Swiss/Ephemeris changes**
   - Keep Objective-C bridging minimal; expose new C functions through `SwissEphBridge.h`.
   - Whenever `ThirdParty/SwissEph` updates, rerun `scripts/ci_validate_swiss.c` and rebuild `lib/libswe.a`.
3. **Location/timezone adjustments**
   - Continue leveraging MapKit APIs only. Update `BirthInfoView` validation copy alongside `DashboardSummaryBuilder` strings for consistency.
4. **Automation tweaks**
   - Mirror simulator version or OS changes across Fastlane and GitHub workflows to avoid drift.
   - Document any new secrets or provisioning artifacts in `GitHubActionsSecrets.md`.

---

## 12. Reference Materials

- `AstrologyCalculations.md` - equation-level description of every calculator.
- `CalculationLogicExplanation.md` - step-by-step explanation for Swiss bridging and derived values.
- `LagnasPageLogic.md` and `LagnasPageLogicDiagrams.md` - diagrams for Hora, Ghatika, and Indu logic.
- `GitHubActionsFlow.md`, `GitHubActionsSecrets.md`, `GitHubSecretsGuide.md` - CI/CD deep dives.
- `FastlaneExplanation.md`, `WorkflowDiagrams.md`, `AppleCodeSigningExplained.md` - tooling and deployment primers.

Use these references when implementing new astrology computations or modifying release automation.

---

## 13. Open Questions and TODOs

- Expand `NotesAppTests/` coverage beyond dashboard summaries and planet kinds to cover calculators and services.
- Broaden UITests to cover every tab plus interactions such as screenshot capture or notification prompts.
- Migrate provisioning secrets to App Store Connect API keys or GitHub OIDC credentials to retire local `.p12` files.
- Consider modularizing calculators into Swift packages if reuse beyond Vedic Light is desired.

Keeping this list visible during planning sessions helps prioritize technical debt along with feature work.

