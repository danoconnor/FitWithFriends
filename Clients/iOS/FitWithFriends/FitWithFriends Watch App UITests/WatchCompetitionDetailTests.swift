//
//  WatchCompetitionDetailTests.swift
//  FitWithFriends Watch App UITests
//
//  Tests for tapping into a competition card and viewing the full leaderboard.
//

import XCTest

final class WatchCompetitionDetailTests: WatchUITestBase {
    func testTapCardOpensDetail() throws {
        let competitionId = try createCompetitionWithHistory(name: "Detail Test", daysInPast: 3)
        try seedCompetitionWithUsers(competitionId: competitionId)
        try seedSelfActivityData(daysAgo: 3,
                                  caloriesBurned: 300, caloriesGoal: 400,
                                  exerciseTime: 25, exerciseTimeGoal: 30,
                                  standTime: 10, standTimeGoal: 12)

        launchApp(loggedIn: true)

        // On watchOS, NavigationLink collapses child views into a single Button
        let card = competitionCard(named: "Detail Test")
        XCTAssertTrue(card.waitForExistence(timeout: 20))

        // Tap the card to navigate to the detail view
        card.tap()

        // Verify the detail view appears — look for Alice Chen in the leaderboard.
        // In the detail view (List, not NavigationLink), text may be exposed as
        // StaticText or within cells. Try both approaches.
        let aliceStatic = app.staticTexts["Alice Chen"]
        let alicePredicate = NSPredicate(format: "label CONTAINS %@", "Alice Chen")
        let aliceInAny = app.descendants(matching: .any).matching(alicePredicate).firstMatch

        XCTAssertTrue(
            aliceStatic.waitForExistence(timeout: 10) || aliceInAny.exists,
            "Alice Chen not found in detail view"
        )

        takeScreenshot(name: "Watch_CompetitionDetail")
    }

    func testDetailShowsAllUsers() throws {
        let competitionId = try createCompetitionWithHistory(name: "Full Leaderboard", daysInPast: 3)
        try seedCompetitionWithUsers(competitionId: competitionId)
        try seedSelfActivityData(daysAgo: 3,
                                  caloriesBurned: 300, caloriesGoal: 400,
                                  exerciseTime: 25, exerciseTimeGoal: 30,
                                  standTime: 10, standTimeGoal: 12)

        launchApp(loggedIn: true)

        // Wait for card and tap into detail
        let card = competitionCard(named: "Full Leaderboard")
        XCTAssertTrue(card.waitForExistence(timeout: 20))
        card.tap()

        // Verify seeded users appear in the leaderboard
        let predicate = { (name: String) -> NSPredicate in
            NSPredicate(format: "label CONTAINS %@", name)
        }

        // Alice Chen should be visible first
        let alice = app.descendants(matching: .any).matching(predicate("Alice Chen")).firstMatch
        XCTAssertTrue(alice.waitForExistence(timeout: 10), "Alice Chen not found")

        let marcus = app.descendants(matching: .any).matching(predicate("Marcus Johnson")).firstMatch
        XCTAssertTrue(marcus.waitForExistence(timeout: 5), "Marcus Johnson not found")

        // Sarah Kim and James Park may require scrolling on smaller watches
        let sarah = app.descendants(matching: .any).matching(predicate("Sarah Kim")).firstMatch
        if !sarah.exists {
            app.swipeUp()
        }
        XCTAssertTrue(sarah.waitForExistence(timeout: 5), "Sarah Kim not found")

        let james = app.descendants(matching: .any).matching(predicate("James Park")).firstMatch
        if !james.exists {
            app.swipeUp()
        }
        XCTAssertTrue(james.waitForExistence(timeout: 5), "James Park not found")

        takeScreenshot(name: "Watch_FullLeaderboard")
    }

    func testBackNavigationFromDetail() throws {
        try createTestCompetition(name: "Nav Test")

        launchApp(loggedIn: true)

        let card = competitionCard(named: "Nav Test")
        XCTAssertTrue(card.waitForExistence(timeout: 20))

        // Tap into detail
        card.tap()

        // Wait for detail to appear
        Thread.sleep(forTimeInterval: 1)

        // Navigate back via the navigation bar back button
        app.navigationBars.buttons.firstMatch.tap()

        // Should be back on the card view with competition card visible
        XCTAssertTrue(card.waitForExistence(timeout: 10))
    }
}
