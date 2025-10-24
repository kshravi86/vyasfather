# GitHub Actions Workflow Explanation: `ios-ipa-build.yml`

## Overview
This document explains the workflow defined in `.github/workflows/ios-ipa-build.yml`, which is responsible for building an iOS IPA (iOS App Store Package) for the project.

## Workflow Trigger
*   **`on: push`**: The workflow is triggered automatically on every `push` event to the `main` branch.
*   **`on: workflow_dispatch`**: The workflow can also be manually triggered from the GitHub Actions UI. It accepts an optional `export_method` input, which defaults to `"app-store-connect"`.

## Jobs
The workflow defines a single job: `build-ipa`.

### Job: `build-ipa`
*   **`runs-on: macos-latest`**: This job runs on a macOS virtual machine provided by GitHub Actions, which is necessary for building iOS applications.
*   **Environment Variables (`env`):** Several environment variables are set using GitHub Secrets, which are securely stored and not exposed in the workflow file. These include:
    *   `IOS_TEAM_ID`: Apple Developer Team ID.
    *   `P12_BASE64`: Base64 encoded `.p12` certificate file.
    *   `P12_PASSWORD`: Password for the `.p12` file.
    *   `PROVISIONING_PROFILE_BASE64`: Base64 encoded provisioning profile.

## Steps within `build-ipa` Job

1.  **`Checkout`**:
    *   **Action:** `uses: actions/checkout@v4`
    *   **Purpose:** Checks out the repository code onto the runner, making it available for the workflow.

2.  **`Setup Xcode`**:
    *   **Action:** `uses: maxim-lobanov/setup-xcode@v1`
    *   **Purpose:** Installs the `latest-stable` version of Xcode on the macOS runner.

3.  **`Show Xcode version`**:
    *   **Command:** `xcodebuild -version`
    *   **Purpose:** Verifies the installed Xcode version.

4.  **`Generate App Icons (blue-white star)`**:
    *   **Command:** `chmod +x scripts/generate_app_icon.swift` and `swift scripts/generate_app_icon.swift`
    *   **Purpose:** Executes a Swift script to generate app icons.

5.  **`Build Swiss Ephemeris static library`**:
    *   **Command:** A multi-line shell script.
    *   **Purpose:** Compiles the C source files of the Swiss Ephemeris library into a static library (`libswe.a`) for `arm64` architecture, which is then used by the iOS application.

6.  **`Validate Swiss positions (host build)`**:
    *   **Command:** A multi-line shell script.
    *   **Purpose:** Builds and runs a host tool (`ci_validate_swiss.c`) to validate the Swiss Ephemeris calculations. This step is marked `continue-on-error: true`, meaning the workflow will proceed even if this validation fails.

7.  **`Import signing certificate`**:
    *   **Action:** `uses: apple-actions/import-codesign-certs@v2`
    *   **Purpose:** Imports the base64 encoded `.p12` certificate into the macOS keychain on the runner, making it available for code signing. This step only runs if `P12_BASE64` secret is provided.

8.  **`Install provisioning profile`**:
    *   **Command:** A multi-line shell script.
    *   **Purpose:** Decodes the base64 encoded provisioning profile and installs it on the runner. It also extracts the `PP_UUID`, `PP_NAME`, and `BUNDLE_ID` into GitHub environment variables for later use. This step only runs if `PROVISIONING_PROFILE_BASE64` secret is provided.

9.  **`Resolve Swift packages`**:
    *   **Command:** `xcodebuild -resolvePackageDependencies -project NotesApp.xcodeproj -scheme NotesApp -clonedSourcePackagesDirPath "$RUNNER_TEMP/SPM"`
    *   **Purpose:** Resolves Swift Package Manager dependencies for the Xcode project.

10. **`Archive (Release, unsigned)`**:
    *   **Command:** `xcodebuild archive ...`
    *   **Purpose:** Archives the iOS application in `Release` configuration. **Crucially, this step explicitly disables code signing (`CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`)**, which means the generated archive is *unsigned*. This is a significant point for App Store compliance.
    *   **Output:** The `xcodebuild.log` is generated and errors/notes are grepped from it.

11. **`Ensure SwissEph data bundled`**:
    *   **Command:** A multi-line shell script.
    *   **Purpose:** Verifies that the Swiss Ephemeris data files (`.se1`) are correctly bundled within the archived `.app` bundle. If not found, it attempts to copy them from the repository. It also checks the size of the IPA to ensure data is present.

12. **`Inspect app binary for Swiss symbols (non-blocking)`**:
    *   **Command:** A multi-line shell script.
    *   **Purpose:** Inspects the app binary to check for the presence of Swiss Ephemeris symbols, indicating successful linking. This step is `continue-on-error: true`.

13. **`Create ExportOptions.plist (manual signing)`**:
    *   **Command:** A multi-line shell script.
    *   **Purpose:** Dynamically generates an `ExportOptions.plist` file. This file specifies how the archive should be exported (e.g., `app-store`, `development`, `release-testing`, `enterprise`). It attempts to detect the export method from the provisioning profile but defaults to `app-store`. It uses `manual` signing style.

14. **`Show ExportOptions for debugging`**:
    *   **Command:** `plutil -p ExportOptions.plist || cat ExportOptions.plist`
    *   **Purpose:** Prints the content of the generated `ExportOptions.plist` for debugging purposes.

15. **`Export IPA`**:
    *   **Command:** `xcodebuild -exportArchive ...`
    *   **Purpose:** Exports the previously created archive into an IPA file using the generated `ExportOptions.plist`. This step performs the actual code signing and packaging into an IPA.

16. **`Verify IPA size (fail if < 1 MB)`**:
    *   **Command:** A multi-line shell script.
    *   **Purpose:** Checks the size of the generated IPA file. If it's less than 1 MB, it indicates a potential issue (e.g., missing Swiss Ephemeris data) and fails the workflow.

17. **`Upload IPA artifact`**:
    *   **Action:** `uses: actions/upload-artifact@v4`
    *   **Purpose:** Uploads the generated IPA file as a workflow artifact, making it downloadable from the GitHub Actions run summary.

## App Store Compliance Note
As identified previously, the `Archive (Release, unsigned)` step explicitly disables code signing. While the `Export IPA` step *does* perform code signing based on the `ExportOptions.plist`, the initial archiving without signing can sometimes lead to issues or is not the recommended practice for a fully compliant App Store build process. For strict App Store compliance, the archiving step should ideally also be signed.
