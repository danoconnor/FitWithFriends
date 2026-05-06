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

    func testUserDetailsView() throws {
        // Create a competition with activity data
        let competitionId = try createCompetitionForScreenshots(name: "User Detail Test", daysInPast: 3)
        try seedCompetitionWithUsers(competitionId: competitionId)
        try seedSelfActivityData(daysAgo: 3,
                                  caloriesBurned: 300, caloriesGoal: 400,
                                  exerciseTime: 25, exerciseTimeGoal: 30,
                                  standTime: 10, standTimeGoal: 12)

        launchApp(loggedIn: true)

        // Wait for the home screen and competition to load
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))
        let competitionText = app.staticTexts["User Detail Test"]
        XCTAssertTrue(competitionText.waitForExistence(timeout: 10))

        // Open competition detail
        competitionText.tap()
        XCTAssertTrue(app.navigationBars["Competition Details"].waitForExistence(timeout: 5))

        // Tap on Alice Chen (first seeded user) to view their daily details
        // Scope to the leaderboard in the detail sheet to avoid matching the home screen leaderboard
        let leaderboard = app.otherElements["competitionLeaderboard"].firstMatch
        XCTAssertTrue(leaderboard.waitForExistence(timeout: 5))
        let userRow = leaderboard.staticTexts["Alice Chen"]
        XCTAssertTrue(userRow.waitForExistence(timeout: 5))
        userRow.tap()

        // Verify user details view appears with total points
        XCTAssertTrue(app.staticTexts["total points"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Alice Chen"].waitForExistence(timeout: 5))

        takeScreenshot(name: "06_UserDailyDetails")
    }

    func testPrivateBadgeShown() throws {
        try createTestCompetition(name: "Private Badge Test")

        launchApp(loggedIn: true)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Private Badge Test"].waitForExistence(timeout: 10))

        // Private competitions should show a "Private" badge
        XCTAssertTrue(app.staticTexts["Private"].waitForExistence(timeout: 5))
    }

    func testCreateCompetitionScoringDropdownExists() {
        launchApp(loggedIn: true)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

        let newCompButton = app.buttons["New Competition"]
        XCTAssertTrue(newCompButton.waitForExistence(timeout: 5))
        newCompButton.tap()

        XCTAssertTrue(app.navigationBars["Create competition"].waitForExistence(timeout: 5))

        // Verify the scoring type dropdown label button exists
        let dropdownButton = app.buttons["Activity Rings"]
        XCTAssertTrue(dropdownButton.waitForExistence(timeout: 3), "Scoring type dropdown should show 'Activity Rings' as the default label")

        // Tap to open the menu
        dropdownButton.tap()

        // Verify the other options appear in the menu
        XCTAssertTrue(app.buttons["Tracked Workouts"].waitForExistence(timeout: 3), "Menu should show 'Tracked Workouts' option")
        XCTAssertTrue(app.buttons["Daily Totals"].waitForExistence(timeout: 3), "Menu should show 'Daily Totals' option")
    }

    func testCreateCompetitionKeyboardDismiss() {
        launchApp(loggedIn: true)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

        let newCompButton = app.buttons["New Competition"]
        XCTAssertTrue(newCompButton.waitForExistence(timeout: 5))
        newCompButton.tap()

        XCTAssertTrue(app.navigationBars["Create competition"].waitForExistence(timeout: 5))

        // Tap the name field and type some text
        let nameField = app.textFields["e.g., January Challenge"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Test")

        // Verify keyboard is visible by checking the Done button exists
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Keyboard Done button should be visible")
        doneButton.tap()

        // After tapping Done the keyboard should be dismissed — wait for the
        // dismissal animation to complete before asserting (synchronous .exists
        // is unreliable on slow CI runners where the animation may still be in progress)
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
    }

    func testCreateCompetitionProUpgradeShownForNonProUser() {
        launchApp(loggedIn: true, isPro: false)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

        let newCompButton = app.buttons["New Competition"]
        XCTAssertTrue(newCompButton.waitForExistence(timeout: 5))
        newCompButton.tap()

        XCTAssertTrue(app.navigationBars["Create competition"].waitForExistence(timeout: 5))

        // Open the scoring type dropdown and select Tracked Workouts (pro-only)
        let dropdownButton = app.buttons["Activity Rings"]
        XCTAssertTrue(dropdownButton.waitForExistence(timeout: 3))
        dropdownButton.tap()

        let trackedWorkoutsOption = app.buttons["Tracked Workouts"]
        XCTAssertTrue(trackedWorkoutsOption.waitForExistence(timeout: 3))
        trackedWorkoutsOption.tap()

        // For a non-pro user selecting a pro-only scoring type, the Upgrade to Pro button should appear
        XCTAssertTrue(app.buttons["Upgrade to Pro"].waitForExistence(timeout: 3),
                      "Upgrade to Pro button should appear for non-pro users selecting a pro scoring type")

        // The Create button should NOT be present
        XCTAssertFalse(app.buttons["Create"].exists,
                       "Create button should not be shown when Upgrade to Pro is required")
    }

    func testCreateCompetitionCreateButtonShownForProUser() {
        launchApp(loggedIn: true, isPro: true)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

        let newCompButton = app.buttons["New Competition"]
        XCTAssertTrue(newCompButton.waitForExistence(timeout: 5))
        newCompButton.tap()

        XCTAssertTrue(app.navigationBars["Create competition"].waitForExistence(timeout: 5))

        // Fill in competition name
        let nameField = app.textFields["e.g., January Challenge"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Pro Competition")

        // For a pro user, the Create button should be visible
        XCTAssertTrue(app.buttons["Create"].waitForExistence(timeout: 3),
                      "Create button should be visible for pro users")

        // Upgrade to Pro button should NOT be present
        XCTAssertFalse(app.buttons["Upgrade to Pro"].exists,
                       "Upgrade to Pro button should not appear for pro users")
    }

    func testCreateCompetitionWorkoutTypeAnyOption() {
        launchApp(loggedIn: true, isPro: true)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

        let newCompButton = app.buttons["New Competition"]
        XCTAssertTrue(newCompButton.waitForExistence(timeout: 5))
        newCompButton.tap()

        XCTAssertTrue(app.navigationBars["Create competition"].waitForExistence(timeout: 5))

        // Open the scoring type dropdown and select Tracked Workouts
        let dropdownButton = app.buttons["Activity Rings"]
        XCTAssertTrue(dropdownButton.waitForExistence(timeout: 3))
        dropdownButton.tap()

        let trackedWorkoutsOption = app.buttons["Tracked Workouts"]
        XCTAssertTrue(trackedWorkoutsOption.waitForExistence(timeout: 3))
        trackedWorkoutsOption.tap()

        // Tap the workout types row to open the picker sheet
        let workoutTypesRow = app.buttons["Workout types"]
        XCTAssertTrue(workoutTypesRow.waitForExistence(timeout: 3))
        workoutTypesRow.tap()

        // Verify "Any workout type" appears at the top of the picker sheet
        XCTAssertTrue(app.staticTexts["Any workout type"].waitForExistence(timeout: 3),
                      "The workout type picker should include an 'Any workout type' option")
    }
}
