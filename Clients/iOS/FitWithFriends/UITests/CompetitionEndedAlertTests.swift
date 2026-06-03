//
//  CompetitionEndedAlertTests.swift
//  FitWithFriends UITests
//
//  Note: the redesign replaces the old `UIAlert` with a full-screen
//  `CompetitionEndView` cover. Tests now look for the screen's accessibility
//  identifier rather than `app.alerts.firstMatch`.
//

import XCTest

final class CompetitionEndedAlertTests: FWFUITestBase {
    private var homeScreen: XCUIElement { app.otherElements["homeScreen"] }
    private var endScreen: XCUIElement { app.staticTexts["competitionEndScreen"] }
    private var endDismissButton: XCUIElement { app.buttons["competitionEndDismiss"] }

    func testAlertShownForArchivedCompetition() throws {
        let competitionId = try createTestCompetition(name: "Finished Competition")
        try setCompetitionArchived(competitionId: competitionId, userPoints: 500)

        launchApp(loggedIn: true)

        XCTAssertTrue(homeScreen.waitForExistence(timeout: 30))
        XCTAssertTrue(endScreen.waitForExistence(timeout: 30))
    }

    func testAlertNotShownAfterDismissal() throws {
        let competitionId = try createTestCompetition(name: "Finished Competition")
        try setCompetitionArchived(competitionId: competitionId, userPoints: 500)

        launchApp(loggedIn: true)
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 30))
        XCTAssertTrue(endScreen.waitForExistence(timeout: 30))

        endDismissButton.tap()
        XCTAssertTrue(endScreen.waitForNonExistence(timeout: 5))

        // Background and foreground the app — the dismissed competition should not
        // reappear on relaunch (the VM marks it seen in UserDefaults).
        XCUIDevice.shared.press(.home)
        app.activate()

        XCTAssertFalse(endScreen.waitForExistence(timeout: 5))
    }

    func testRematchOpensCreateWizard() throws {
        let competitionId = try createTestCompetition(name: "Rematch Competition")
        try setCompetitionArchived(competitionId: competitionId, userPoints: 500)

        launchApp(loggedIn: true)

        XCTAssertTrue(homeScreen.waitForExistence(timeout: 30))
        XCTAssertTrue(endScreen.waitForExistence(timeout: 30))

        // Tapping the rematch / new-competition CTA must dismiss the end cover AND
        // open the create wizard (the bug: the cover dismissed but nothing followed).
        let rematchButton = app.buttons["competitionEndRematchButton"]
        XCTAssertTrue(rematchButton.waitForExistence(timeout: 5))
        rematchButton.tap()

        XCTAssertTrue(endScreen.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["createWizard"].waitForExistence(timeout: 10))

        takeScreenshot(name: "12_RematchCreateWizard")
    }

    func testProcessingResultsCompetitionDoesNotShowAlert() throws {
        try createTestCompetition(name: "Still Processing")

        launchApp(loggedIn: true)
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))
        XCTAssertFalse(endScreen.waitForExistence(timeout: 3))
    }

    func testNoAlertWhenNoCompetitions() {
        launchApp(loggedIn: true)
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))
        XCTAssertFalse(endScreen.waitForExistence(timeout: 3))
    }
}
