import Foundation
import XCTest

@objc public class Snapshot: NSObject {
    @objc public class func setupFastlaneSnapshot() {
        let app = XCUIApplication()
        app.launchArguments.append("-FASTLANE_SNAPSHOT")
        app.launch()
    }
}
