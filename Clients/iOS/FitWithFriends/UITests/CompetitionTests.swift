//
//  CompetitionTests.swift
//  FitWithFriends UITests
//
//  Created by Dan O'Connor on 3/27/26.
//

import XCTest

final class CompetitionTests: FWFUITestBase {
    func testCreateCompetition() {
        launchApp(loggedIn: true)

        // Wait for the home screen to load
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

        // Tap "New Competition" button
        let newCompButton = app.buttons["New Competition"]
        XCTAssertTrue(newCompButton.waitForExistence(timeout: 5))
        newCompButton.tap()

        // Verify the create competition form appears
        XCTAssertTrue(app.navigationBars["Create competition"].waitForExistence(timeout: 5))

        // Fill in competition name
        let nameField = app.textFields["e.g., January Challenge"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("My Test Competition")

        takeScreenshot(name: "04_CreateCompetition")

        // Tap Create button
        let createButton = app.buttons["Create"]
        XCTAssertTrue(createButton.exists)
        createButton.tap()

        // Verify the sheet dismisses and we return to the home screen
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

        // The new competition should appear
        XCTAssertTrue(app.staticTexts["My Test Competition"].waitForExistence(timeout: 10))
    }

    func testCompetitionDetail() throws {
        // Create a test competition via the backend API
        try createTestCompetition(name: "Detail Test Competition")

        launchApp(loggedIn: true)

        // Wait for the home screen to load and competition to appear
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))
        let competitionText = app.staticTexts["Detail Test Competition"]
        XCTAssertTrue(competitionText.waitForExistence(timeout: 10))

        // Tap the competition to open detail
        competitionText.tap()

        // Verify detail view appears
        XCTAssertTrue(app.navigationBars["Competition Details"].waitForExistence(timeout: 5))

        takeScreenshot(name: "05_CompetitionDetail")
    }

    func testPrivateBadgeShown() throws {
        try createTestCompetition(name: "Private Badge Test")

        launchApp(loggedIn: true)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Private Badge Test"].waitForExistence(timeout: 10))

        // Private competitions should show a "Private" badge
        XCTAssertTrue(app.staticTexts["Private"].waitForExistence(timeout: 5))
    }
}
