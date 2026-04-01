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

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

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

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Pro Challenge"].waitForExistence(timeout: 10))

        // Non-pro user should see the upgrade button instead of a join button
        let upgradeButton = app.buttons["Upgrade to Pro"]
        XCTAssertTrue(upgradeButton.waitForExistence(timeout: 5))

        takeScreenshot(name: "07_UpgradeToProButton")
    }

    func testProUpgradeSheetAppears() throws {
        try createPublicCompetition(name: "Sheet Test")

        launchApp(loggedIn: true)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Sheet Test"].waitForExistence(timeout: 10))

        let upgradeButton = app.buttons["Upgrade to Pro"].firstMatch
        XCTAssertTrue(upgradeButton.waitForExistence(timeout: 5))
        upgradeButton.tap()

        // Verify the Pro upgrade sheet is presented with the expected content
        XCTAssertTrue(app.navigationBars["Pro"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Upgrade to Pro"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Public Competitions"].waitForExistence(timeout: 3))

        takeScreenshot(name: "08_ProUpgradeSheet")
    }

    func testProUpgradeSheetDismisses() throws {
        try createPublicCompetition(name: "Dismiss Test")

        launchApp(loggedIn: true)

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Dismiss Test"].waitForExistence(timeout: 10))

        app.buttons["Upgrade to Pro"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Pro"].waitForExistence(timeout: 5))

        app.buttons["Done"].tap()

        // Verify we returned to the home screen after dismissing the sheet
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 5))
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

        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))

        // Joined public competition appears in "Your Competitions" with a "Public" badge
        XCTAssertTrue(app.staticTexts["Your Competitions"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Joined Public Competition"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Public"].waitForExistence(timeout: 5))

        takeScreenshot(name: "09_JoinedPublicCompetition")
    }

    // MARK: - Private

    /// Create a public competition via the admin endpoint and return the competition ID.
    /// Public competitions are created outside the test user's normal competition list,
    /// so the base class tearDown cleanup (which uses GET /competitions) will not remove
    /// them. They are isolated by the test user's unique ID per run, so they will not
    /// interfere with other test runs.
    @discardableResult
    private func createPublicCompetition(name: String = "UI Test Public Competition") throws -> String {
        let startDate = ISO8601DateFormatter().string(from: Date())
        let endDate = ISO8601DateFormatter().string(from: Date(timeIntervalSinceNow: 7 * 24 * 60 * 60))

        let url = URL(string: "http://localhost:3000/admin/createPublicCompetition")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("some_admin_secret", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "displayName": name,
            "startDate": startDate,
            "endDate": endDate,
            "ianaTimezone": TimeZone.current.identifier,
            "adminUserId": userId!
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        var responseData: Data?
        var httpResponse: HTTPURLResponse?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { data, response, _ in
            responseData = data
            httpResponse = response as? HTTPURLResponse
            semaphore.signal()
        }.resume()
        semaphore.wait()

        XCTAssertEqual(httpResponse?.statusCode, 200, "Failed to create public competition")
        let json = try JSONSerialization.jsonObject(with: responseData!) as! [String: Any]
        return json["competition_id"] as! String
    }
}
