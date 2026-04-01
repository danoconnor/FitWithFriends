//
//  HomeScreenTests.swift
//  FitWithFriends UITests
//
//  Created by Dan O'Connor on 3/27/26.
//

import XCTest

final class HomeScreenTests: FWFUITestBase {
    func testHomeScreenWithCompetition() throws {
        // Create a test competition via the backend API before launching the app
        try createTestCompetition(name: "Screenshot Competition")

        launchApp(loggedIn: true)

        // Wait for the home screen to load
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

        // Verify the competition is visible
        XCTAssertTrue(app.staticTexts["Screenshot Competition"].waitForExistence(timeout: 10))

        // Verify the competitions section header
        XCTAssertTrue(app.staticTexts["Your Competitions"].exists)

        takeScreenshot(name: "02_HomeScreen")
    }

    func testHomeScreenEmptyState() {
        launchApp(loggedIn: true)

        // Wait for the home screen to load
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

        // Verify empty state message
        XCTAssertTrue(app.staticTexts["No competitions yet"].waitForExistence(timeout: 5))

        takeScreenshot(name: "03_HomeScreen_Empty")
    }
}
