//
//  SnapshotHelper.swift
//  Example
//
//  Created by Felix Krause on 10/8/15.
//  Copyright © 2015 Felix Krause. All rights reserved.
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
        #if swift(>=5.0)
            let query = XCUIApplication().statusBars.children(matching: .other).element.children(matching: .other).element.children(matching: .other)
        #else
            let query = XCUIApplication().statusBars.children(matching: .other).element.children(matching: .other).element.children(matching: .other)
        #endif
        let networkLoadingIndicator = query.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
        let isLoadingIndicatorVisible = networkLoadingIndicator.exists
        if isLoadingIndicatorVisible {
            #if swift(>=4.2)
                waitForElementToDisappear(element: networkLoadingIndicator)
            #else
                waitForElementToDisappear(element: networkLoadingIndicator)
            #endif
        }
    #endif
}

func waitForElementToDisappear(element: XCUIElement) {
    let timeout = 300
    let existsPredicate = NSPredicate(format: "exists == false")

    expectation(for: existsPredicate,
                evaluatedWith: element, handler: nil)

    waitForExpectations(timeout: TimeInterval(timeout)) { (error) -> Void in
        if error != nil {
            let message = "Failed to find \(element) after \(timeout) seconds."
            print(message)
        }
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

        if waitForAnimations {
            sleep(1) // Executing a sleep statement right after calling app.launch()
        }
    }

    class func setLanguage(_ app: XCUIApplication) {
        guard let prefix = pathPrefix() else {
            return
        }

        let path = prefix.appendingPathComponent("language.txt")

        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            deviceLanguage = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
            app.launchArguments += ["-AppleLanguages", "(\(deviceLanguage))"]
        } catch {
            print("Couldn't detect/set language...")
        }
    }

    class func setLocale(_ app: XCUIApplication) {
        guard let prefix = pathPrefix() else {
            return
        }

        let path = prefix.appendingPathComponent("locale.txt")

        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            locale = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
        } catch {
            print("Couldn't detect/set locale...")
        }

        if locale.isEmpty && !deviceLanguage.isEmpty {
            locale = Locale(identifier: deviceLanguage).identifier
        }

        if !locale.isEmpty {
            app.launchArguments += ["-AppleLocale", "\(locale)"]
        }
    }

    class func setLaunchArguments(_ app: XCUIApplication) {
        guard let prefix = pathPrefix() else {
            return
        }

        let path = prefix.appendingPathComponent("snapshot-launch_arguments.txt")
        app.launchArguments += ["-FASTLANE_SNAPSHOT", "YES", "-ui_testing"]

        do {
            let launchArguments = try String(contentsOf: path, encoding: String.Encoding.utf8)
            let regex = try NSRegularExpression(pattern: "(\\\".+?\\\"|\\S+)", options: [])
            let matches = regex.matches(in: launchArguments, options: [], range: NSRange(location: 0, length: launchArguments.count))
            let results = matches.map { result -> String in
                (launchArguments as NSString).substring(with: result.range)
            }
            app.launchArguments += results
        } catch {
            print("Couldn't detect/set launch_arguments...")
        }
    }

    public static func snapshot(_ name: String, waitForLoadingIndicator: Bool = true) {
        if waitForLoadingIndicator {
            waitForLoadingIndicatorToDisappear()
        }

        print("snapshot: \(name)") // more information about this, check out https://docs.fastlane.tools/actions/snapshot/#how-does-it-work

        sleep(1) // Waiting for the animation to be finished (kind of)

        #if os(OSX)
            XCUIApplication().typeKey(XCUIKeyboardKeySecondaryFn, modifierFlags: [])
        #else
            let screenshot = XCUIScreen.main.screenshot()
            guard var simulator = ProcessInfo().environment["SIMULATOR_DEVICE_NAME"], let screenshotsDir = screenshotsDirectory else { return }
            do {
                let path = screenshotsDir.appendingPathComponent("\(simulator)-\(name).png")
                try screenshot.pngRepresentation.write(to: path)
            } catch let error {
                print("Problem writing screenshot: \(name) to \(screenshotsDir)/\(simulator)-\(name).png")
                print(error)
            }
        #endif
    }

    class func pathPrefix() -> URL? {
        if let cacheDir = self.cacheDirectory {
            return cacheDir
        }

        let homeDir: URL
        #if os(OSX)
            homeDir = URL(fileURLWithPath: NSHomeDirectory())
        #else
            homeDir = URL(fileURLWithPath: NSHomeDirectory())
        #endif

        #if os(OSX)
            let libraryDir = homeDir.appendingPathComponent("Library")
        #else
            let libraryDir = homeDir.appendingPathComponent("tmp")
        #endif

        let cacheDir = libraryDir.appendingPathComponent("Caches")

        guard let bundleID = Bundle.main.bundleIdentifier else { return nil }
        let snapshotDir = cacheDir.appendingPathComponent(bundleID)

        self.cacheDirectory = snapshotDir
        return snapshotDir
    }
}

// Please don't remove the lines below
// They are used to detect outdated configuration files
// SnapshotHelperVersion [1.30]