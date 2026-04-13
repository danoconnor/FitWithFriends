//
//  CompetitionEndedAlertTests.swift
//  FitWithFriends UITests
//

import XCTest

final class CompetitionEndedAlertTests: FWFUITestBase {
    func testAlertShownForArchivedCompetition() throws {
        let competitionId = try createTestCompetition(name: "Finished Competition")
        try setCompetitionArchived(competitionId: competitionId, userPoints: 500)

        launchApp(loggedIn: true)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 30))

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 30))
        XCTAssertTrue(alert.staticTexts["Finished Competition has ended!"].exists)
        XCTAssertTrue(
            alert.staticTexts.matching(NSPredicate(format: "label CONTAINS 'place'")).firstMatch.waitForExistence(timeout: 3)
        )
    }

    func testAlertNotShownAfterDismissal() throws {
        let competitionId = try createTestCompetition(name: "Finished Competition")
        try setCompetitionArchived(competitionId: competitionId, userPoints: 500)

        launchApp(loggedIn: true)
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 30))
        app.alerts.firstMatch.buttons["OK"].tap()

        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 3))

        // Background and foreground the app
        XCUIDevice.shared.press(.home)
        app.activate()

        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 5))
    }

    func testProcessingResultsCompetitionDoesNotShowAlert() throws {
        try createTestCompetition(name: "Still Processing")

        launchApp(loggedIn: true)
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 3))
    }

    func testNoAlertWhenNoCompetitions() {
        launchApp(loggedIn: true)
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 3))
    }
}
