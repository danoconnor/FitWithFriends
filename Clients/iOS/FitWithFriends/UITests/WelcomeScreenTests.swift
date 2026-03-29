//
//  WelcomeScreenTests.swift
//  FitWithFriends UITests
//
//  Created by Dan O'Connor on 3/27/26.
//

import XCTest

final class WelcomeScreenTests: FWFUITestBase {
    func testWelcomeScreenAppearance() {
        launchApp(loggedIn: false)

        // Verify welcome screen elements
        XCTAssertTrue(app.staticTexts["Fit With Friends"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Compete. Move. Win."].exists)

        // The Sign In with Apple button should be present
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Sign in with Apple'")).firstMatch.waitForExistence(timeout: 3))

        takeScreenshot(name: "01_WelcomeScreen")
    }
}
