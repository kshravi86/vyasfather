# Vyasfather / Vedic Light

Vyasfather (distributed as **Vedic Light**) is a SwiftUI iOS/iPadOS experience that transforms precise astronomical data from the Swiss Ephemeris into practical Vedic astrology insights. Users enter their birth details once and swipe through themed dashboards for Dashas, Panchanga, special lagnas, divisional charts, deity recommendations, and auspicious flags.

## Feature Highlights

- **Planetary Engine** - `PlanetaryCalculator.swift` feeds off the Swiss Ephemeris bridge (`SwissEphBridge.h`, `SwissEphWrapper.m`) to derive sidereal planet positions, ascendant, and house cusps.
- **Deep Astrology Coverage** - Tabs span Vimshottari Dasha, Panchanga, Navamsha/Saptamsha, Jaimini Karakas, Yogi & Avayogi, Ishta/Palana Devata, Pushkara Navamsha, and 64th Navamsha / 22nd Drekkana sensitive points.
- **Matchmaking** - A dedicated tab contrasts two charts, scoring Moon tara, elemental flow, and ascendant resonance with quick partner inputs.
- **Dashboard UX** - `ContentView.swift` and `DashboardSummaryBuilder.swift` produce a cosmic dashboard with toast-driven feedback, sync badges, tab-aware theming, and deterministic screenshot helpers.
- **Location-aware inputs** - `LocationSearchManager.swift` wraps MapKit autocomplete to fetch accurate coordinates/timezones for the calculator pipeline.
- **Automation-ready** - Fastlane (`fastlane/Fastfile`, `Snapfile`) and GitHub Actions workflows compile Swiss Ephemeris, run tests, export signed IPAs, and capture deterministic screenshots per tab.

## Architecture Snapshot

1. **Presentation layer** – SwiftUI views (`BirthInfoView`, `DashaTabView`, `MainTabView`, `UIStyles`) bind `@State` birth metadata to calculator outputs.
2. **Domain/calculation layer** – Pure Swift engines (`VimshottariDashaCalculator`, `PanchangaCalc`, `VargaCalculatorIOS`, `YogiCalculator`, `SixtyFourTwentyTwoCalc`, `IshtaDevataCalc`) transform planetary data into the structures each tab consumes.
3. **Services** – `LocationSearchManager`, `NotificationManager`, `PersistenceController`, `SnapshotHelper`, `ScreenshotMode` wrap Apple frameworks, Core Data, and screenshot-specific state.
4. **Infrastructure** – `ThirdParty/SwissEph`, `.github/workflows`, `scripts/`, Fastlane, and provisioning assets handle astrophysics data, CI/CD, and distribution.

For an end-to-end explanation, see `docs/ProjectDocumentation.md`.

## Getting Started

```bash
git clone https://github.com/kshravi86/vyasfather.git
cd vyasfather
gem install bundler        # once per machine
bundle install             # installs Fastlane dependencies
open NotesApp.xcodeproj    # launches Xcode
```

1. Select the `NotesApp` scheme and an iOS/iPadOS simulator (iPhone 15 Pro or iPad Pro 13" M4 recommended).
2. Press `⌘R`. The default Bengaluru birth data renders every tab immediately so layouts are visible without manual input.
3. To rebuild the Swiss Ephemeris static library locally, reuse the shell snippet in `.github/workflows/ios-appstore-upload-v3.yml` (compiles `ThirdParty/SwissEph/src/*.c` into `ThirdParty/SwissEph/lib/libswe.a`).

## Testing

- **Unit tests**: `NotesAppTests/` currently covers `DashboardSummaryBuilder` and `PlanetKind`. Run via `⌘U` in Xcode or
  ```bash
  xcodebuild ^
    -project NotesApp.xcodeproj ^
    -scheme NotesApp ^
    -destination "platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5" ^
    test
  ```
  (On macOS shells, replace `^` with `\`.)
- **UI tests & screenshots**: Expand `NotesAppUITests/` for tab navigation coverage, then run `bundle exec fastlane screenshots` to generate App Store imagery per the `Snapfile`.
- **Continuous Integration**: `.github/workflows/ios-tests.yml` replicates `xcodebuild test` on macOS 14 runners once the Swiss build helper script is in place.

## Code Quality & Linting

- **SwiftLint** keeps SwiftUI and calculator files consistent. Install it via `brew install swiftlint` (or Mint) and run `scripts/swiftlint.sh` before opening a PR. The root `.swiftlint.yml` opts into whitespace/alignment rules while excluding generated Swiss Ephemeris sources so signal remains high.
- **Xcode Build Phase**: To see lint warnings inline, add a "Run Script" phase that executes `scripts/swiftlint.sh`. The helper script simply shells out to `swiftlint lint --strict` and forwards any CLI flags you provide.
- **Hydration helpers**: Legacy hydration screens now flow through `HydrationSettingsStore` (see `NotesApp/HydrationHelpers.swift`) which canonicalises cup sizes, applies sane defaults, and surfaces Core Data save errors via `HydrationLogError`. Use those helpers instead of talking to Core Data directly.

## Tooling & Deployment

- **Fastlane**: `fastlane/Fastfile` provides a `screenshots` lane; extend with `beta`/`release` lanes as you automate TestFlight or App Store Connect submissions. `Snapfile` targets the iPad Pro 13" simulator and writes to `fastlane/screenshots/`.
- **GitHub Actions**: `ios-appstore-upload-v3.yml` and `ios-build-ipa.yml` compile Swiss Ephemeris, archive `NotesApp`, ensure `.se1` data ships, export signed IPAs, and upload artifacts. Populate secrets (`IOS_TEAM_ID`, `P12_BASE64`, `P12_PASSWORD`, `PROVISIONING_PROFILE_BASE64`) for code signing.
- **Screenshot workflows**: `working-*.yml`, `ipad-screenshots.yml`, and related jobs spin up deterministic simulator runs for each feature tab, saving PNGs to `iOS-Screenshots-5/`.

## Documentation

- **Primary guide**: `docs/ProjectDocumentation.md` (architecture, modules, build/test/deploy guidance, extensibility tips).
- **Topic-specific references**: `AstrologyCalculations.md`, `CalculationLogicExplanation.md`, `GitHubActionsFlow.md`, `FastlaneExplanation.md`, `DependencyManagement.md`, `LagnasPageLogic*.md`, `WorkflowDiagrams.md`, `CurrentSecretsExplained.md`.

## Contributing & License

- Follow modern Swift style (Swift 5.10, SwiftUI-first) and accompany new calculators or tabs with relevant unit/UI tests.
- Run `xcodebuild test` locally before opening PRs; CI jobs assume tests pass with the Swiss Ephemeris static library built.
- License information is not yet published—treat the codebase as proprietary unless the owner specifies otherwise.
