//
//  PublicCompetitionTests.swift
//  FitWithFriends UITests
//
//  Created by Dan O'Connor on 3/29/26.
//

import XCTest

final class PublicCompetitionTests: FWFUITestBase {
    func testPublicCompetitionDisplayed() throws {
        try createPublicCompetition(name: "Weekly Challenge")

        launchApp(loggedIn: true)

        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 10))

        // Verify the public competitions section header and competition name appear
        XCTAssertTrue(app.staticTexts["Public Competitions"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Weekly Challenge"].waitForExistence(timeout: 5))

        // The public competition card should show a "Public" badge
        XCTAssertTrue(app.staticTexts["Public"].waitForExistence(timeout: 5))

        takeScreenshot(name: "06_PublicCompetitions")
    }

    func testUpgradeToProButtonShown() throws {
        try createPublicCompetition(name: "Pro Challenge")

        launchApp(loggedIn: true)

        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Pro Challenge"].waitForExistence(timeout: 10))

        // Non-pro user should see the upgrade button instead of a join button
        let upgradeButton = app.buttons["Upgrade to Pro"]
        XCTAssertTrue(upgradeButton.waitForExistence(timeout: 5))

        takeScreenshot(name: "07_UpgradeToProButton")
    }

    func testProUpgradeSheetAppears() throws {
        try createPublicCompetition(name: "Sheet Test")

        launchApp(loggedIn: true)

        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Sheet Test"].waitForExistence(timeout: 10))

        let upgradeButton = app.buttons["Upgrade to Pro"].firstMatch
        XCTAssertTrue(upgradeButton.waitForExistence(timeout: 5))
        upgradeButton.tap()

        // SubscriptionStoreView provides its own Close button — verify the sheet appeared
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 5))

        takeScreenshot(name: "08_ProUpgradeSheet")
    }

    func testProUpgradeSheetDismisses() throws {
        try createPublicCompetition(name: "Dismiss Test")

        launchApp(loggedIn: true)

        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Dismiss Test"].waitForExistence(timeout: 10))

        app.buttons["Upgrade to Pro"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 5))

        app.buttons["Close"].tap()

        // The Close button must disappear — if it's still present the sheet never dismissed
        XCTAssertTrue(app.buttons["Close"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 5))
    }

    func testPublicBadgeShownWhenJoined() throws {
        let competitionId = try createPublicCompetition(name: "Joined Public Competition")

        // Make user pro and join the competition via API before launching the app
        try makeUserPro()

        let url = URL(string: "http://localhost:3000/competitions/joinPublic")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["competitionId": competitionId])

        var joinResponse: HTTPURLResponse?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { _, response, _ in
            joinResponse = response as? HTTPURLResponse
            semaphore.signal()
        }.resume()
        semaphore.wait()
        XCTAssertEqual(joinResponse?.statusCode, 200, "Failed to join public competition")

        launchApp(loggedIn: true)

        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 10))

        // Joined public competition appears in the active competitions group with a "Public" badge
        XCTAssertTrue(app.staticTexts["Active now"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Joined Public Competition"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Public"].waitForExistence(timeout: 5))

        takeScreenshot(name: "09_JoinedPublicCompetition")
    }

    /// End-to-end: a Pro user discovers a public competition they have not joined, taps the
    /// card to preview its live leaderboard + scoring rules (served by the non-member
    /// publicOverview endpoint), then joins from the preview and sees it land in their
    /// active competitions.
    func testPublicCompetitionDetailPreviewAndJoinEndToEnd() throws {
        let competitionId = try createPublicCompetition(name: "Preview & Join Challenge")

        // Seed the competition with members + activity so the preview leaderboard has real data
        try seedCompetitionWithUsers(competitionId: competitionId)

        // Backend must see the user as Pro for the join to succeed
        try makeUserPro()

        // App must see the user as Pro (drives the Join vs Upgrade button in UI tests)
        launchApp(loggedIn: true, isPro: true)

        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 10))

        // The card appears in the Public Competitions section with the details affordance
        XCTAssertTrue(app.staticTexts["Preview & Join Challenge"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["View leaderboard & scoring"].waitForExistence(timeout: 5))

        // Tapping the card opens the preview sheet
        app.staticTexts["Preview & Join Challenge"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["publicCompetitionDetailScreen"].waitForExistence(timeout: 10))

        // The live leaderboard loaded from the publicOverview endpoint with the seeded members
        XCTAssertTrue(app.otherElements["publicCompetitionLeaderboard"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Leaderboard"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Alice Chen"].waitForExistence(timeout: 10))

        takeScreenshot(name: "10_PublicCompetitionDetail")

        // The scoring rules sheet opens from the detail header
        let helpButton = app.buttons["scoringRulesButton"]
        XCTAssertTrue(helpButton.waitForExistence(timeout: 5))
        helpButton.tap()
        XCTAssertTrue(app.staticTexts["HOW SCORING WORKS"].waitForExistence(timeout: 5))
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["HOW SCORING WORKS"].waitForNonExistence(timeout: 5))

        // Join from the preview
        let joinButton = app.buttons["publicCompetitionJoinButton"]
        XCTAssertTrue(joinButton.waitForExistence(timeout: 5))
        joinButton.tap()

        // The preview dismisses and the now-joined competition appears in the active group
        XCTAssertTrue(app.staticTexts["publicCompetitionDetailScreen"].waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Active now"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Preview & Join Challenge"].waitForExistence(timeout: 15))
    }

    /// A non-Pro user can still open the preview, but the join CTA is replaced by an
    /// Upgrade to Pro action.
    func testPublicCompetitionDetailShowsUpgradeForNonPro() throws {
        let competitionId = try createPublicCompetition(name: "Locked Preview Challenge")
        try seedCompetitionWithUsers(competitionId: competitionId)

        // Non-pro user (no makeUserPro, no isPro launch flag)
        launchApp(loggedIn: true)

        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Locked Preview Challenge"].waitForExistence(timeout: 10))

        app.staticTexts["Locked Preview Challenge"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["publicCompetitionDetailScreen"].waitForExistence(timeout: 10))

        // Non-pro users see the upgrade CTA instead of a join button
        XCTAssertTrue(app.buttons["publicCompetitionUpgradeButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["publicCompetitionJoinButton"].exists)

        takeScreenshot(name: "11_PublicCompetitionDetailUpgrade")
    }

}
