# GitHub Actions Workflow Reference

This document explains every workflow under `.github/workflows/`, why it exists, which triggers it listens to, the key steps in each job, and the secrets or inputs it expects. Use it when debugging CI failures, onboarding new contributors, or planning automation changes.

---

## 1. Workflow Inventory

| File | Purpose | Trigger | Notes |
| --- | --- | --- | --- |
| `ios-tests.yml` | Run unit + UI tests on each push/PR. | `push`, `pull_request`, manual dispatch. | Builds Swiss Ephemeris once, runs `xcodebuild test` on macOS 14. |
| `ios-build-ipa.yml` | Produce an unsigned archive, sign/export IPA, and upload artifact. | `push` to `main`, manual dispatch with optional export method. | Requires signing secrets, validates Swiss data, ensures `.se1` payload bundled. |
| `ios-appstore-upload-v3.yml` | Fully signed archive export plus upload to App Store Connect. | Manual dispatch (`workflow_dispatch`). | Uses environment-scoped secrets; uploads via API key or Apple ID fallback. |
| `ipad-screenshots.yml` | Runs Fastlane screenshots (with simctl fallback). | Manual dispatch. | Builds Swiss for simulator, executes `bundle exec fastlane screenshots`, then ensures at least one PNG exists. |
| `ipad-shot-level1.yml` | Same as above but always Fastlane-first for iPad. | Manual dispatch. | Slightly lighter fallback logic, designed for “level 1” screenshot runs. |
| `ipad-sim-screenshot.yml` | Capture a single iPad simulator screenshot without Fastlane. | Manual dispatch. | Minimal steps: build sim app, boot device, capture screenshot. |
| `working.yml` | Single screenshot capture (general tab). | Manual dispatch. | Base template the tab-specific workflows reuse. |
| `working-all.yml` | Capture five themed iPad shots (birth, dasha, ishtadevta, yogi, panchanga). | Manual dispatch. | Loops tabs, stores PNGs as artifacts. |
| `working-all-iphone.yml` | Same as `working-all` but for iPhone, plus ImageMagick resize. | Manual dispatch. | Produces 1284×2778 crops when `magick` is present. |
| `working-d9.yml` (and `working-dasha.yml`, `working-ishtadevta.yml`, `working-jaimini.yml`, `working-lagnas.yml`, `working-panchanga.yml`, `working-uttama.yml`, `working-yogi.yml`) | Capture a single iPad screenshot targeting the named tab. | Manual dispatch. | Only difference is the `--tab` launch argument and artifact name. |
| `ipad-sim-screenshot.yml` | Single-shot fallback (identical to `working.yml` but under “iPad” naming). | Manual dispatch. | Used when Fastlane is not desired. |

> **Note:** Every “working-*.yml” file follows the same simulator build + screenshot recipe. Differences are limited to the `name`, default simulator device, and `--tab` launch argument.

---

## 2. Core CI Workflows

### `ios-tests.yml`

- **Trigger:** Pushes and PRs targeting `main`, plus manual dispatch.
- **Runner:** `macos-14`.
- **Key steps:**
  1. `actions/checkout@v4`.
  2. Force-select Xcode 15.4 to match local toolchain.
  3. `scripts/build_swiss.sh` compiles Swiss Ephemeris for iOS targets.
  4. Runs `xcodebuild test` against `NotesApp` on the iPhone 15 Pro (iOS 17.5) simulator with `set -o pipefail`.
- **Outputs:** Xcode logs in job output; no artifacts.
- **Secrets:** None.
- **Usage tips:** Keep `scripts/build_swiss.sh` updated when Swiss vendoring changes. If simulator OS bumps, update the `-destination` string both here and in Fastlane to avoid drift.

### `ios-build-ipa.yml`

- **Trigger:** Pushes to `main` and manual runs with optional `export_method`.
- **Runner:** `macos-latest`.
- **Secrets required:** `IOS_TEAM_ID`, `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `PROVISIONING_PROFILE_BASE64`.
- **Flow:**
  1. Checkout and install the latest stable Xcode via `maxim-lobanov/setup-xcode`.
  2. Generate the blue-white star icons using `scripts/generate_app_icon.swift`.
  3. Compile Swiss Ephemeris for device architectures into `ThirdParty/SwissEph/lib/libswe.a`.
  4. Optionally validate Swiss calculations using `scripts/ci_validate_swiss.c`.
  5. Import signing certificates and install provisioning profiles, capturing UUID/name/bundle ID in `$GITHUB_ENV`.
  6. Resolve Swift Package dependencies once (reused by later build steps).
  7. Run an unsigned archive build with Swiss library flags to generate `App.xcarchive`.
  8. Explicitly ensure `.se1` Swiss data exists inside the `.app` bundle and log sample files.
  9. Inspect binary symbols (non-blocking) to confirm Swiss linkage.
 10. Generate `ExportOptions.plist`, auto-detecting export method based on the provisioning profile unless an input overrides it.
 11. Export a signed IPA, fail if the file is <1 MB (indicates missing Swiss data).
 12. Upload the IPA via `actions/upload-artifact`.
- **Artifacts:** `iOS-IPA-<run-number>` containing the exported IPA.
- **Notes:** This workflow does not upload to App Store Connect; it is optimized for QA builds/testing. Use `ios-appstore-upload-v3.yml` for distribution.

### `ios-appstore-upload-v3.yml`

- **Trigger:** Manual dispatch with optional `environment` input (drives environment-scoped secrets).
- **Runner:** `macos-latest`.
- **Secrets required:** `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `KEYCHAIN_PASSWORD`, `PROVISIONING_PROFILE_BASE64`, `IOS_TEAM_ID`. Optional App Store Connect secrets: either API key trio (`APP_STORE_CONNECT_*`) or Apple ID credentials (`APP_STORE_CONNECT_USERNAME`, `APP_SPECIFIC_PASSWORD`).
- **Flow highlights:**
  1. Checkout + Xcode setup, then regenerate app icons.
  2. Build Swiss Ephemeris static lib for device builds.
  3. Compute a timestamp build number (`date +%Y%m%d%H%M`) and export it to `$GITHUB_ENV`.
  4. Preflight ensures the key secrets exist; prints warnings if uploads will be skipped.
  5. Install certificates into a temporary keychain and place provisioning profile in `~/Library/MobileDevice/Provisioning Profiles`.
  6. Detect the signing certificate flavor automatically (`Apple Distribution` vs `iOS Distribution`).
  7. Archive the app with Release configuration, embedding the Swiss library.
  8. Extract metadata (bundle ID, CFBundleShortVersionString, build number) directly from the archive.
  9. Construct a tailored `export-options.plist` and export a signed IPA.
 10. Upload IPA artifact for retention (90 days).
 11. If API-key secrets are present, upload the IPA via `xcrun altool --apiKey/--apiIssuer`. Otherwise, fall back to Apple ID credentials.
 12. Always delete the temporary keychain at the end to avoid certificate leaks.
- **Usage tips:** Keep environment secrets synchronized between GitHub environments (e.g., `prod`, `staging`). When migrating to App Store Connect API keys fully, remove Apple ID credentials to reduce maintenance.

---

## 3. Screenshot Automation

### Fastlane-driven iPad workflows

| File | Intent | Highlights |
| --- | --- | --- |
| `ipad-screenshots.yml` | Primary screenshot run that invokes Fastlane and, if needed, simctl fallback. | Installs Ruby 3.3, runs `bundle exec fastlane screenshots`. If Fastlane yields zero PNGs, it builds a simulator app and manually captures a screenshot into `fastlane/screenshots/en-US/iPad13_fallback_01.png`. |
| `ipad-shot-level1.yml` | A lighter variant of the above, also Fastlane-first. | Uses the same Ruby setup, Swiss build, and fallback logic but is meant for “level 1” screenshot refreshes; environment variables for signing are exported for future expansion. |

Both workflows:
- Trigger manually with an optional `device` input (default `iPad Pro 13-inch (M4)`).
- Build Swiss Ephemeris for the simulator to ensure `libswe.a` links against the SwiftUI target.
- Upload whatever PNGs exist under `fastlane/screenshots` as artifacts.

### Manual simulator screenshot workflows

These workflows all share the same skeleton:

1. Checkout + latest Xcode.
2. Build Swiss Ephemeris for the iOS simulator, writing `ThirdParty/SwissEph/lib/libswe.a`.
3. Resolve Swift packages and build the `NotesApp` simulator binary (Debug configuration).
4. Optionally copy `.se1` assets into `APP_DIR/SwissEph`.
5. Boot the requested simulator (`device` input, defaulting to iPad Pro 13" M4) and install the .app.
6. Launch with deterministic arguments: `--seed-screenshots --disable-animations` plus an optional `--tab <name>`.
7. Capture PNG(s) via `xcrun simctl io <udid> screenshot`.
8. Upload the PNG directory via `actions/upload-artifact`.

Rather than repeat the same logic, the repository uses multiple files so that each tab can be triggered independently from the Actions UI.

#### Templates and multi-page variants

- **`working.yml`** – Baseline single screenshot (first/birth tab). Artifact name: `iPad-Sim-Screenshot`.
- **`working-all.yml`** – Captures five iPad shots (`birth`, `dasha`, `ishtadevta`, `yogi`, `panchanga`) in one run. Saves them as `iPadSim_<n>_<tab>.png`.
- **`working-all-iphone.yml`** – Same as `working-all` but targets `iPhone 16 Pro` by default. After screenshots, it optionally uses ImageMagick (`magick`) to crop to Apple’s 1284×2778 size, storing results in `sim_screenshots/final/`.

#### Tab-specific variants

| Workflow file | `--tab` launch argument | Artifact |
| --- | --- | --- |
| `working-dasha.yml` | `dasha` | `iPad-Sim-Screenshot-Dasha` |
| `working-ishtadevta.yml` | `ishtadevta` | `iPad-Sim-Screenshot-IshtaDevata` |
| `working-yogi.yml` | `yogi` | `iPad-Sim-Screenshot-Yogi` |
| `working-panchanga.yml` | `panchanga` | `iPad-Sim-Screenshot-Panchanga` |
| `working-jaimini.yml` | `jaimini` | `iPad-Sim-Screenshot-Jaimini` |
| `working-lagnas.yml` | `lagnas` | `iPad-Sim-Screenshot-Lagnas` |
| `working-uttama.yml` | `uttama` | `iPad-Sim-Screenshot-Uttama` |
| `working-d9.yml` | `d9` | `iPad-Sim-Screenshot-D9` |
| `working.yml` | *(no tab argument; renders landing state)* | `iPad-Sim-Screenshot` |

All of them accept a `device` input, default to iPad Pro 13" (M4), and name screenshots `iPadSim_<tab>_01.png`.

#### Other helpers

- **`ipad-sim-screenshot.yml`** – Functionally identical to `working.yml` but branded for iPad-only single captures; use it when Fastlane fails and you just need one fallback image.
- **`working-all-iphone.yml`** – The only workflow that resizes images to Apple’s iPhone portrait spec using ImageMagick if present. It uploads both the resized and original PNGs.

---

## 4. Required Secrets and Inputs Summary

| Workflow | Secrets | Inputs |
| --- | --- | --- |
| `ios-tests.yml` | None | None |
| `ios-build-ipa.yml` | `IOS_TEAM_ID`, `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `PROVISIONING_PROFILE_BASE64` | `export_method` (optional) |
| `ios-appstore-upload-v3.yml` | `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `KEYCHAIN_PASSWORD`, `PROVISIONING_PROFILE_BASE64`, `IOS_TEAM_ID`, plus either `APP_STORE_CONNECT_*` API secrets or `APP_STORE_CONNECT_USERNAME`/`APP_SPECIFIC_PASSWORD`. | `environment` (defaults to `prod`) |
| Screenshot workflows | None (Fastlane variants read Git secrets only if you extend them). | All accept `device` (string). |

---

## 5. Tips for Extending or Debugging Workflows

1. **Keep Swiss build scripts in sync.** Almost every workflow compiles Swiss Ephemeris manually. If the vendor sources move or compiler flags change, update all scripts together (consider extracting a reusable composite action to reduce duplication).
2. **Align simulator OS versions.** `xcodebuild` destinations, Fastlane `Snapfile`, and screenshot workflows should target the same OS version to avoid mismatched cached runtimes.
3. **Artifacts for reproducibility.** Screenshot workflows only store PNGs; if you need logs, consider adding `actions/upload-artifact` for `xcodebuild.log` to speed up debugging.
4. **Use workflow inputs wisely.** The `device` input makes it easy to test on alternate simulators (e.g., `iPad Pro (11-inch) (M4)`). Update defaults instead of editing workflow logic when Apple refreshes hardware names.
5. **Environment-scoped secrets.** `ios-appstore-upload-v3.yml` reads secrets via the workflow’s `environment`. Configure `prod`, `staging`, etc., in GitHub so rotations don’t require YAML changes.

With this reference, you can reason about where each automation fits—tests vs. IPA builds vs. screenshot capture—and make changes confidently.
