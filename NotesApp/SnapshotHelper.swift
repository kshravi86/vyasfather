import Foundation
import XCTest

@objc public class Snapshot: NSObject {
    @objc public class func setupFastlaneSnapshot() {
        // This is called before the UI test starts.
        // You can put any setup code here.
        
        // Set a launch argument to indicate that the app is running in UI Test mode
        let app = XCUIApplication()
        app.launchArguments.append("-FASTLANE_SNAPSHOT")
        app.launch()
    }
}
