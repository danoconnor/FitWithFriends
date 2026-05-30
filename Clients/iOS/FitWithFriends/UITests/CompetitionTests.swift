//
//  CompetitionTests.swift
//  FitWithFriends UITests
//
//  Created by Dan O'Connor on 3/27/26.
//
//  Updated for the redesigned 3-step create wizard (Templates → Scoring → Invite).
//  Tests tap "Start blank" on Step 1 to land on the scoring step, then drive the
//  scoring config. The old single-form flow no longer exists.
//

import XCTest

final class CompetitionTests: FWFUITestBase {
    private var homeScreen: XCUIElement { app.otherElements["homeScreen"] }
    private var createWizard: XCUIElement { app.otherElements["createWizard"] }
    private var competitionDetailScreen: XCUIElement { app.staticTexts["competitionDetailScreen"] }

    private var createButton: XCUIElement { app.buttons["createCompetitionButton"] }
    private var startBlankButton: XCUIElement { app.buttons["createWizardStartBlank"] }
    private var submitButton: XCUIElement { app.buttons["createCompetitionSubmitButton"] }
    private var proUpgradeButton: XCUIElement { app.buttons["createCompetitionProUpgradeButton"] }

    /// Tap "Start a new competition" then "Start blank" so we're on Step 2 (scoring).
    /// Most wizard tests want to drive the scoring config directly without picking a template.
    private func openScoringStep() {
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()

        XCTAssertTrue(createWizard.waitForExistence(timeout: 5))
        XCTAssertTrue(startBlankButton.waitForExistence(timeout: 3))
        startBlankButton.tap()
    }

    func testCreateCompetition() {
        launchApp(loggedIn: true)
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))

        openScoringStep()

        // Fill in competition name
        let nameField = app.textFields["e.g., January Challenge"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("My Test Competition")

        takeScreenshot(name: "04_CreateCompetition")

        // Tap Create button — uses an accessibility label of "Create" so we can
        // match the legacy expectation, but identifier is more reliable.
        XCTAssertTrue(submitButton.waitForExistence(timeout: 3))
        submitButton.tap()

        // Wizard advances to the Invite step on success — we're still inside the
        // sheet, so the home screen is hidden behind it. Verify the new competition
        // appears in the manager (it should land in the invite step's share card).
        XCTAssertTrue(app.staticTexts["My Test Competition"].waitForExistence(timeout: 10))
    }

    func testCompetitionDetail() throws {
        // Create a test competition via the backend API
        try createTestCompetition(name: "Detail Test Competition")

        launchApp(loggedIn: true)

        // Wait for the home screen to load and competition to appear
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))
        let competitionText = app.staticTexts["Detail Test Competition"]
        XCTAssertTrue(competitionText.waitForExistence(timeout: 15))

        // Tap the competition to open detail
        competitionText.tap()

        // Verify detail view appears (replaces the old `Competition Details` nav bar)
        XCTAssertTrue(competitionDetailScreen.waitForExistence(timeout: 5))

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
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))
        let competitionText = app.staticTexts["User Detail Test"]
        XCTAssertTrue(competitionText.waitForExistence(timeout: 15))

        // Open competition detail
        competitionText.tap()
        XCTAssertTrue(competitionDetailScreen.waitForExistence(timeout: 5))

        // Tap on Alice Chen (first seeded user) to view their daily details.
        // Scope to the leaderboard in the detail sheet to avoid matching the
        // home screen leaderboard.
        let leaderboard = app.otherElements["competitionLeaderboard"].firstMatch
        XCTAssertTrue(leaderboard.waitForExistence(timeout: 5))
        let userRow = leaderboard.staticTexts["Alice Chen"]
        XCTAssertTrue(userRow.waitForExistence(timeout: 5))
        userRow.tap()

        // Verify user details view appears with the Alice Chen header.
        // The redesigned daily details uses inline navigation title.
        XCTAssertTrue(app.navigationBars["Alice Chen"].waitForExistence(timeout: 10))

        takeScreenshot(name: "06_UserDailyDetails")
    }

    func testPrivateBadgeShown() throws {
        try createTestCompetition(name: "Private Badge Test")

        launchApp(loggedIn: true)

        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Private Badge Test"].waitForExistence(timeout: 10))

        // Private competitions should show a "Private" badge
        XCTAssertTrue(app.staticTexts["Private"].waitForExistence(timeout: 5))
    }

    func testCreateCompetitionScoringDropdownExists() {
        launchApp(loggedIn: true)
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))

        openScoringStep()

        // The redesign replaces the dropdown menu with a segmented control. All
        // three scoring modes are visible at the same time.
        XCTAssertTrue(app.buttons["scoringMode_Rings"].waitForExistence(timeout: 3),
                      "Rings segment should be visible")
        XCTAssertTrue(app.buttons["scoringMode_Daily"].exists,
                      "Daily segment should be visible")
        XCTAssertTrue(app.buttons["scoringMode_Workouts"].exists,
                      "Workouts segment should be visible")
    }

    func testCreateCompetitionKeyboardDismiss() {
        launchApp(loggedIn: true)
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))

        openScoringStep()

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
        // dismissal animation to complete before asserting.
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
    }

    func testCreateCompetitionProUpgradeShownForNonProUser() {
        launchApp(loggedIn: true, isPro: false)
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))

        openScoringStep()

        // Switch to a Pro-only scoring mode
        let workoutsSegment = app.buttons["scoringMode_Workouts"]
        XCTAssertTrue(workoutsSegment.waitForExistence(timeout: 3))
        workoutsSegment.tap()

        // For a non-pro user selecting a pro-only scoring type, the wizard's
        // submit button is the Pro upgrade CTA (accessibility label "Upgrade to Pro").
        XCTAssertTrue(proUpgradeButton.waitForExistence(timeout: 3),
                      "Pro upgrade CTA should appear in the wizard for non-pro users selecting a pro scoring type")

        // The regular Create button should NOT be present
        XCTAssertFalse(submitButton.exists,
                       "Create button should not be shown when Pro upgrade is required")
    }

    func testCreateCompetitionCreateButtonShownForProUser() {
        launchApp(loggedIn: true, isPro: true)
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))

        openScoringStep()

        // Fill in competition name so canSubmit is true
        let nameField = app.textFields["e.g., January Challenge"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Pro Competition")

        // For a pro user, the Create button should be visible
        XCTAssertTrue(submitButton.waitForExistence(timeout: 3),
                      "Create button should be visible for pro users")

        // Pro upgrade button should NOT be present
        XCTAssertFalse(proUpgradeButton.exists,
                       "Pro upgrade CTA should not appear for pro users")
    }

    func testCreateCompetitionWorkoutTypeAnyOption() {
        launchApp(loggedIn: true, isPro: true)
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))

        openScoringStep()

        // Switch to the Workouts mode
        let workoutsSegment = app.buttons["scoringMode_Workouts"]
        XCTAssertTrue(workoutsSegment.waitForExistence(timeout: 3))
        workoutsSegment.tap()

        // Open the workout types picker sheet
        let workoutTypesButton = app.buttons["workoutTypesPickerButton"]
        XCTAssertTrue(workoutTypesButton.waitForExistence(timeout: 3))
        workoutTypesButton.tap()

        // Verify "Any workout type" appears at the top of the picker sheet
        XCTAssertTrue(app.staticTexts["Any workout type"].waitForExistence(timeout: 3),
                      "The workout type picker should include an 'Any workout type' option")
    }
}
