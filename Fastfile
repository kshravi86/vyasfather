fastlane_version "2.217.0"

default_platform :ios

platform :ios do
  desc "Takes screenshots for the App Store"
  lane :screenshots do
    # Ensure you have a UI Test target configured in your Xcode project
    # and a Snapfile configured for the devices and languages you need.
    # This will run the UI tests and capture screenshots.
    snapshot
  end
end
