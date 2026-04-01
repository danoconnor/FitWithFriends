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

        // Wait for the home screen to load
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

        // Open the toolbar menu and tap About
        let menuButton = app.buttons["More"]
        if menuButton.waitForExistence(timeout: 3) {
            menuButton.tap()
        } else {
            // Try the ellipsis/gear icon
            let gearButton = app.navigationBars.buttons.element(boundBy: 0)
            gearButton.tap()
        }

        let aboutButton = app.buttons["About"]
        XCTAssertTrue(aboutButton.waitForExistence(timeout: 3))
        aboutButton.tap()

        // Verify the about screen
        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Version"].exists)

        takeScreenshot(name: "06_AboutScreen")
    }
}
