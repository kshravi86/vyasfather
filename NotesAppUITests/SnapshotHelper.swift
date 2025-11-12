//
//  SnapshotHelper.swift
//  Copied for UITest bundle
//

import Foundation
import XCTest

var deviceLanguage = ""
var locale = ""

func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
    Snapshot.setupSnapshot(app, waitForAnimations: waitForAnimations)
}

func snapshot(_ name: String, waitForLoadingIndicator: Bool) {
    if waitForLoadingIndicator {
        waitForLoadingIndicatorToDisappear()
    }
    Snapshot.snapshot(name, waitForLoadingIndicator: waitForLoadingIndicator)
}

func snapshot(_ name: String) {
    Snapshot.snapshot(name, waitForLoadingIndicator: true)
}

func waitForLoadingIndicatorToDisappear() {
    #if os(tvOS)
        XCUIApplication().otherElements.deviceStatusBars.networkLoadingIndicators.allElementsBoundByIndex.first?.waitForNonExistence(timeout: 60)
    #else
        let query = XCUIApplication().statusBars.children(matching: .other).element.children(matching: .other).element.children(matching: .other)
        let networkLoadingIndicator = query.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
        let isLoadingIndicatorVisible = networkLoadingIndicator.exists
        if isLoadingIndicatorVisible {
            waitForElementToDisappear(element: networkLoadingIndicator)
        }
    #endif
}

func waitForElementToDisappear(element: XCUIElement) {
    let timeout = 300
    let existsPredicate = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: existsPredicate, object: element)
    let result = XCTWaiter.wait(for: [expectation], timeout: TimeInterval(timeout))
    if result != .completed {
        print("Failed to find \(element) after \(timeout) seconds.")
    }
}

@objc public class Snapshot: NSObject {
    public static var cacheDirectory: URL?
    public static var screenshotsDirectory: URL? {
        return cacheDirectory?.appendingPathComponent("screenshots", isDirectory: true)
    }

    public static func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
        setLanguage(app)
        setLocale(app)
        setLaunchArguments(app)
        app.launch()
        if waitForAnimations { sleep(1) }
    }

    class func setLanguage(_ app: XCUIApplication) {
        guard let prefix = pathPrefix() else { return }
        let path = prefix.appendingPathComponent("language.txt")
        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            deviceLanguage = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
            app.launchArguments += ["-AppleLanguages", "(\(deviceLanguage))"]
        } catch { print("Couldn't detect/set language...") }
    }

    class func setLocale(_ app: XCUIApplication) {
        guard let prefix = pathPrefix() else { return }
        let path = prefix.appendingPathComponent("locale.txt")
        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            locale = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
        } catch { print("Couldn't detect/set locale...") }
        if locale.isEmpty && !deviceLanguage.isEmpty { locale = Locale(identifier: deviceLanguage).identifier }
        if !locale.isEmpty { app.launchArguments += ["-AppleLocale", "\(locale)"] }
    }

    class func setLaunchArguments(_ app: XCUIApplication) {
        guard let prefix = pathPrefix() else { return }
        let path = prefix.appendingPathComponent("snapshot-launch_arguments.txt")
        app.launchArguments += ["-FASTLANE_SNAPSHOT", "YES", "-ui_testing"]
        do {
            let launchArguments = try String(contentsOf: path, encoding: .utf8)
            let regex = try NSRegularExpression(pattern: "(\\\".+?\\\"|\\S+)", options: [])
            let matches = regex.matches(in: launchArguments, options: [], range: NSRange(location: 0, length: launchArguments.count))
            let results = matches.map { result -> String in (launchArguments as NSString).substring(with: result.range) }
            app.launchArguments += results
        } catch { print("Couldn't detect/set launch_arguments...") }
    }

    public static func snapshot(_ name: String, waitForLoadingIndicator: Bool = true) {
        if waitForLoadingIndicator { waitForLoadingIndicatorToDisappear() }
        print("snapshot: \(name)")
        sleep(1)
        let screenshot = XCUIScreen.main.screenshot()
        guard let simulator = ProcessInfo().environment["SIMULATOR_DEVICE_NAME"], let screenshotsDir = screenshotsDirectory else { return }
        do {
            let path = screenshotsDir.appendingPathComponent("\(simulator)-\(name).png")
            try screenshot.pngRepresentation.write(to: path)
        } catch {
            print("Problem writing screenshot: \(name) to \(String(describing: screenshotsDirectory))")
            print(error)
        }
    }

    class func pathPrefix() -> URL? {
        if let cacheDir = self.cacheDirectory { return cacheDir }
        let homeDir = URL(fileURLWithPath: NSHomeDirectory())
        let libraryDir = homeDir.appendingPathComponent("tmp")
        let cacheDir = libraryDir.appendingPathComponent("Caches")
        guard let bundleID = Bundle.main.bundleIdentifier else { return nil }
        let snapshotDir = cacheDir.appendingPathComponent(bundleID)
        self.cacheDirectory = snapshotDir
        return snapshotDir
    }
}

// SnapshotHelperVersion [1.30]
