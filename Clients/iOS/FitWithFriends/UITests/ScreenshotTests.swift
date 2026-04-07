//
//  ScreenshotTests.swift
//  FitWithFriends UITests
//
//  Captures App Store screenshots. Run via scripts/capture_screenshots.sh.
//  Requires the Docker backend to be running (Scripts/start-ui-test-backend.sh).
//

import XCTest

final class ScreenshotTests: FWFUITestBase {

    /// 01 — Welcome / sign-in screen
    func test01_WelcomeScreen() {
        launchApp(loggedIn: false)

        XCTAssertTrue(app.staticTexts["Fit With Friends"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Compete. Move. Win."].exists)
        XCTAssertTrue(app.buttons["signInButton"].waitForExistence(timeout: 3))

        takeScreenshot(name: "01_WelcomeScreen")
    }

    /// 02 — Home screen with an active competition and a full leaderboard
    func test02_HomeScreen() throws {
        let competitionId = try createCompetitionForScreenshots(name: "Summer Challenge")
        try seedCompetitionWithUsers(competitionId: competitionId)
        try seedSelfActivityData(daysAgo: 5, caloriesBurned: 340, caloriesGoal: 400,
                                  exerciseTime: 27, exerciseTimeGoal: 30,
                                  standTime: 11, standTimeGoal: 12)

        launchApp(loggedIn: true)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Summer Challenge"].waitForExistence(timeout: 10))

        takeScreenshot(name: "02_HomeScreen")
    }

    /// 03 — Competition detail view with a full leaderboard
    func test03_CompetitionDetail() throws {
        let competitionId = try createCompetitionForScreenshots(name: "Summer Challenge")
        try seedCompetitionWithUsers(competitionId: competitionId)
        try seedSelfActivityData(daysAgo: 5, caloriesBurned: 340, caloriesGoal: 400,
                                  exerciseTime: 27, exerciseTimeGoal: 30,
                                  standTime: 11, standTimeGoal: 12)

        launchApp(loggedIn: true)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))
        let competitionText = app.staticTexts["Summer Challenge"]
        XCTAssertTrue(competitionText.waitForExistence(timeout: 10))
        competitionText.tap()

        XCTAssertTrue(app.navigationBars["Competition Details"].waitForExistence(timeout: 5))

        takeScreenshot(name: "03_CompetitionDetail")
    }

    /// 04 — Create competition sheet with name filled in
    func test04_CreateCompetition() {
        launchApp(loggedIn: true)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

        let newCompButton = app.buttons["New Competition"]
        XCTAssertTrue(newCompButton.waitForExistence(timeout: 5))
        newCompButton.tap()

        XCTAssertTrue(app.navigationBars["Create competition"].waitForExistence(timeout: 5))

        let nameField = app.textFields["e.g., January Challenge"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Summer Fitness Challenge")

        takeScreenshot(name: "04_CreateCompetition")
    }

    /// 05 — Pro upgrade sheet
    func test05_ProUpgradeSheet() throws {
        try createPublicCompetition(name: "Community Run")

        launchApp(loggedIn: true)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Community Run"].waitForExistence(timeout: 10))

        let upgradeButton = app.buttons["Upgrade to Pro"].firstMatch
        XCTAssertTrue(upgradeButton.waitForExistence(timeout: 5))
        upgradeButton.tap()

        XCTAssertTrue(app.navigationBars["Pro"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Upgrade to Pro"].waitForExistence(timeout: 3))

        takeScreenshot(name: "05_ProUpgradeSheet")
    }
}
