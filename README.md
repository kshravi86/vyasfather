# Vyasfather App

## Project Description

Vyasfather is a mobile application designed to provide astrological calculations and insights. It aims to offer a comprehensive tool for users interested in Vedic astrology, featuring various Lagna calculations, Dasha systems, planetary positions, and more.

## Key Features

*   **Special Lagnas Calculation**: Ghatika Lagna, Hora Lagna (Standard and Jaimini), Indu Lagna.
*   **Planetary Positions**: Accurate calculation of planetary longitudes.
*   **Dasha Systems**: (e.g., Vimshottari Dasha - *details to be added*).
*   **Yogi Points**: (e.g., Yogi, Avayogi, Duplicate Yogi - *details to be added*).
*   **User-friendly Interface**: Intuitive design for easy navigation and data input.

## Technologies Used

*   **Frontend**: SwiftUI
*   **Backend/Calculations**: Swift, C (via Swiss Ephemeris library)
*   **Dependency Management**: RubyGems (for Fastlane)
*   **CI/CD**: GitHub Actions, Fastlane
*   **Database**: Core Data (for notes/user data - *details to be added*)

## Setup Instructions

To get a local copy of the project up and running, follow these steps:

### Prerequisites

*   Xcode (latest stable version recommended)
*   macOS operating system
*   Git
*   Ruby and Bundler (for Fastlane)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/kshravi86/vyasfather.git
    cd vyasfather
    ```

2.  **Install Ruby dependencies (Fastlane):**
    ```bash
    bundle install
    ```

3.  **Open in Xcode:**
    Open `NotesApp.xcodeproj` in Xcode.

4.  **Configure Code Signing:**
    *   Ensure you have valid Apple Developer Program membership.
    *   Set up your development team and provisioning profiles in Xcode's Signing & Capabilities settings for the `NotesApp` target.

## Build and Run

1.  Select the `NotesApp` scheme and a target device or simulator in Xcode.
2.  Click the "Run" button (▶) or press `Cmd + R` to build and run the application.

## Testing

*   **Unit Tests**: (Instructions on how to run unit tests - *to be added*)
*   **UI Tests**: (Instructions on how to run UI tests - *to be added*)

## Deployment

This project uses Fastlane and GitHub Actions for automated deployment to TestFlight and the App Store. Refer to `GitHubActionsFlow.md` for details on the CI/CD workflows.

## Visual Documentation (Screenshots)

To provide visual context for the application's features, you can add screenshots to the `docs/screenshots/` directory (create if it doesn't exist). Reference these screenshots in relevant documentation files or directly in this `README.md`.

## Contributing

(Guidelines for contributing to the project - *to be added*)

## License

(License information - *to be added*)
