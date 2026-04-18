//
//  WatchHomeScreenTests.swift
//  FitWithFriends Watch App UITests
//
//  Tests for the Watch app's root screen states: signed out, no competitions,
//  and competition cards.
//

import XCTest

final class WatchHomeScreenTests: WatchUITestBase {
    func testSignedOutState() {
        launchApp(loggedIn: false)

        // SignedOutView displays "Sign in on iPhone"
        let signInText = app.staticTexts["Sign in on iPhone"]
        XCTAssertTrue(signInText.waitForExistence(timeout: 15))

        takeScreenshot(name: "Watch_SignedOut")
    }

    func testNoCompetitionsState() {
        launchApp(loggedIn: true)

        // NoCompetitionsView displays "No competitions"
        let noCompText = app.staticTexts["No competitions"]
        XCTAssertTrue(noCompText.waitForExistence(timeout: 20))

        takeScreenshot(name: "Watch_NoCompetitions")
    }

    func testCompetitionCardDisplayed() throws {
        let competitionId = try createCompetitionWithHistory(name: "Spring Showdown", daysInPast: 3)
        try seedCompetitionWithUsers(competitionId: competitionId)
        try seedSelfActivityData(daysAgo: 3,
                                  caloriesBurned: 300, caloriesGoal: 400,
                                  exerciseTime: 25, exerciseTimeGoal: 30,
                                  standTime: 10, standTimeGoal: 12)

        launchApp(loggedIn: true)

        // On watchOS, NavigationLink collapses child views into a single Button
        // whose label contains all text content. Query buttons by label predicate.
        let card = competitionCard(named: "Spring Showdown")
        XCTAssertTrue(card.waitForExistence(timeout: 20))

        // Verify top-3 leaderboard data is present in the card's label
        XCTAssertTrue(card.label.contains("Alice Chen"))

        takeScreenshot(name: "Watch_CompetitionCard")
    }

    func testMultipleCompetitions() throws {
        try createTestCompetition(name: "Competition A")
        try createTestCompetition(name: "Competition B")

        launchApp(loggedIn: true)

        // At least one competition card should be visible
        let cardA = competitionCard(named: "Competition A")
        let cardB = competitionCard(named: "Competition B")
        XCTAssertTrue(cardA.waitForExistence(timeout: 20) || cardB.waitForExistence(timeout: 5))

        takeScreenshot(name: "Watch_MultipleCompetitions")
    }
}
