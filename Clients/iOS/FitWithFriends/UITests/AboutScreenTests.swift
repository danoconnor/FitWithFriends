//
//  AboutScreenTests.swift
//  FitWithFriends UITests
//
//  Created by Dan O'Connor on 3/27/26.
//

import XCTest

final class AboutScreenTests: FWFUITestBase {
    func testAboutScreen() {
        launchApp(loggedIn: true)

        // Wait for the home screen to load — allow extra time in CI where app launch is slow
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 30))

        // Open the toolbar settings menu and tap About
        let menuButton = app.buttons["SettingsMenu"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 10))
        menuButton.tap()

        // SwiftUI toolbar menu animations can be slow in CI; use a generous timeout
        let aboutButton = app.buttons["AboutMenuButton"]
        XCTAssertTrue(aboutButton.waitForExistence(timeout: 10))
        aboutButton.tap()

        // Verify the about screen
        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Version"].exists)

        takeScreenshot(name: "06_AboutScreen")
    }
}
