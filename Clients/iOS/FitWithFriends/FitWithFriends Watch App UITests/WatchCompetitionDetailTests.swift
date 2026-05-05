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
        XCTAssertTrue(card.waitForExistence(timeout: 30))

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
        XCTAssertTrue(card.waitForExistence(timeout: 30))
        card.tap()

        // The detail view uses .carousel list style, which shows one row per page.
        // We need to swipe up to advance through leaderboard entries.
        let predicate = { (name: String) -> NSPredicate in
            NSPredicate(format: "label CONTAINS %@", name)
        }

        // Verify at least one seeded user is visible in the detail view
        let alice = app.descendants(matching: .any).matching(predicate("Alice Chen")).firstMatch
        XCTAssertTrue(alice.waitForExistence(timeout: 10), "Alice Chen not found")

        // Scroll through the carousel to find remaining users
        let userNames = ["Marcus Johnson", "Sarah Kim", "James Park"]
        for name in userNames {
            let element = app.descendants(matching: .any).matching(predicate(name)).firstMatch
            if !element.exists {
                app.swipeUp()
            }
            XCTAssertTrue(element.waitForExistence(timeout: 5), "\(name) not found")
        }

        takeScreenshot(name: "Watch_FullLeaderboard")
    }

    func testBackNavigationFromDetail() throws {
        let competitionId = try createCompetitionWithHistory(name: "Nav Test", daysInPast: 3)
        try seedCompetitionWithUsers(competitionId: competitionId)

        launchApp(loggedIn: true)

        let card = competitionCard(named: "Nav Test")
        XCTAssertTrue(card.waitForExistence(timeout: 30))

        // Tap into detail
        card.tap()

        // Wait for detail view content to appear
        let alicePredicate = NSPredicate(format: "label CONTAINS %@", "Alice Chen")
        let detailContent = app.descendants(matching: .any).matching(alicePredicate).firstMatch
        XCTAssertTrue(detailContent.waitForExistence(timeout: 10), "Detail view did not appear")

        // On watchOS, the back button is a standalone Button (identifier "BackButton")
        // but with .carousel list style it may not be hittable (behind carousel content).
        // Use coordinate-based tap to bypass the hittability wait.
        let backButton = app.buttons["BackButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Back button not found")
        backButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        // Should be back on the card view with competition card visible
        XCTAssertTrue(card.waitForExistence(timeout: 10))
    }
}
