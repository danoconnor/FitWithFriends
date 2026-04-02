//
//  FirstLaunchScreenTests.swift
//  FitWithFriends UITests
//
//  Created by Dan O'Connor on 4/1/26.
//

import XCTest

final class FirstLaunchScreenTests: FWFUITestBase {
    func testFirstLaunchScreenAppearance() {
        launchApp(loggedIn: false, showFirstLaunchScreen: true)

        // Sheet should appear automatically on first launch
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Welcome to'")).firstMatch.waitForExistence(timeout: 5))

        // Feature rows
        XCTAssertTrue(app.staticTexts["Compete with Friends"].exists)
        XCTAssertTrue(app.staticTexts["Apple Watch Required"].exists)
        XCTAssertTrue(app.staticTexts["Create or Join"].exists)

        // Continue button
        XCTAssertTrue(app.buttons["Continue"].exists)

        takeScreenshot(name: "05_FirstLaunchScreen")
    }

    func testFirstLaunchContinueDismissesSheetAndShowsSignIn() {
        launchApp(loggedIn: false, showFirstLaunchScreen: true)

        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
        app.buttons["Continue"].tap()

        // Sheet should be gone
        XCTAssertTrue(app.buttons["Continue"].waitForNonExistence(timeout: 5))

        // WelcomeView sign-in button should be visible and tappable
        XCTAssertTrue(app.buttons["signInButton"].waitForExistence(timeout: 3))

        takeScreenshot(name: "06_AfterFirstLaunchDismissed")
    }
}
