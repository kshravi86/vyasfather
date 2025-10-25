import XCTest

final class NotesAppUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testTakeScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["--seed-screenshots", "--disable-animations"]
        app.launch()

        snapshot("01-Home")

        let dashaLabel = "Dasha"
        if let el = element(withLabel: dashaLabel, app: app) { el.tap() }
        snapshot("02-Dasha")

        let yogiLabel = "Yogi"
        if let el = element(withLabel: yogiLabel, app: app) { el.tap() }
        snapshot("03-Yogi")
    }

    private func element(withLabel label: String, app: XCUIApplication) -> XCUIElement? {
        if app.buttons[label].waitForExistence(timeout: 5) { return app.buttons[label] }
        if app.staticTexts[label].exists { return app.staticTexts[label] }
        if app.otherElements[label].exists { return app.otherElements[label] }
        return nil
    }
}

