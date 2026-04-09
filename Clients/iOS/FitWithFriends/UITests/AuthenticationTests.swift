//
//  AuthenticationTests.swift
//  FitWithFriends UITests
//
//  Created by Dan O'Connor on 3/27/26.
//

import XCTest

final class AuthenticationTests: FWFUITestBase {
    func testLogout() {
        launchApp(loggedIn: true)

        // Wait for the home screen to load
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

        // Open the toolbar settings menu and tap Logout
        let menuButton = app.buttons["SettingsMenu"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        menuButton.tap()

        let logoutButton = app.buttons["Logout"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5))
        logoutButton.tap()

        // Verify we're back at the welcome screen
        XCTAssertTrue(app.staticTexts["Fit With Friends"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Compete. Move. Win."].exists)
    }
}
