//
//  HomeScreenTests.swift
//  FitWithFriends UITests
//
//  Created by Dan O'Connor on 3/27/26.
//

import XCTest

final class HomeScreenTests: FWFUITestBase {
    private var homeScreen: XCUIElement {
        app.otherElements["homeScreen"]
    }

    func testHomeScreenWithCompetition() throws {
        // Create a test competition via the backend API before launching the app
        try createTestCompetition(name: "Screenshot Competition")

        launchApp(loggedIn: true)

        // Wait for the home screen to load
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))

        // Verify the competition is visible
        XCTAssertTrue(app.staticTexts["Screenshot Competition"].waitForExistence(timeout: 15))

        // Verify the competitions section header (active competitions group)
        XCTAssertTrue(app.staticTexts["Active now"].exists)

        takeScreenshot(name: "02_HomeScreen")
    }

    func testHomeScreenEmptyState() {
        launchApp(loggedIn: true)

        // Wait for the home screen to load
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))

        // Verify empty state message — wait longer since the empty state now requires a network
        // fetch to complete before the loading spinner clears.
        XCTAssertTrue(app.staticTexts["No competitions yet"].waitForExistence(timeout: 15))

        takeScreenshot(name: "03_HomeScreen_Empty")
    }
}
