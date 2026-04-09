//
//  FWFUITestBase.swift
//  FitWithFriends UITests
//
//  Created by Dan O'Connor on 3/27/26.
//

import XCTest

class FWFUITestBase: XCTestCase {
    private static let backendBaseURL = "http://localhost:3000"

    /// Base64-encoded "clientId:clientSecret" for the test OAuth client
    private static let basicAuthHeader = "Basic NkE3NzNDMzItNUVCMy00MUM5LTgwMzYtQjk5MUI1MUYxNEY3OjExMjc5RUQ0LTI2ODctNDA4RC05QUU3LTIyQUIzQ0E0MTIxOQ=="

    var app: XCUIApplication!

    /// Access token obtained from the Docker backend
    private(set) var accessToken: String?

    /// Access token expiry as ISO8601 string
    private(set) var accessTokenExpiry: String?

    /// Refresh token used to obtain the access token
    private(set) var refreshToken: String?

    /// User ID from the backend
    private(set) var userId: String?

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Health check: verify Docker backend is running
        try checkBackendIsRunning()

        // Obtain an access token from the backend
        try obtainAccessToken()

        // Delete any competitions left over from previous tests or runs
        deleteAllCompetitions()
    }

    override func tearDownWithError() throws {
        // Clean up after the test so the next test starts with a clean state
        deleteAllCompetitions()
    }

    // MARK: - App Launch Helpers

    /// Launch the app in UI testing mode
    /// - Parameters:
    ///   - loggedIn: If true, inject access token so the app starts in logged-in state.
    ///   - loginOutcome: Optional outcome for the sign-in button tap. Pass `"success"` or
    ///     `"failure"` to have the mock Apple auth immediately resolve instead of staying in progress.
    ///   - showFirstLaunchScreen: If true, do NOT suppress the first-launch welcome sheet.
    ///     Defaults to false so the sheet never blocks unrelated tests.
    func launchApp(loggedIn: Bool = true, loginOutcome: String? = nil, showFirstLaunchScreen: Bool = false) {
        app = XCUIApplication()
        app.launchEnvironment["FWF_UI_TESTING"] = "1"

        if showFirstLaunchScreen {
            // Signal the app to reset the first-launch UserDefault before the view model
            // reads it, so the sheet always appears. Using an env var (not a launch arg)
            // avoids the volatile-domain problem where launch args prevent programmatic
            // UserDefaults writes from being visible within the same session.
            app.launchEnvironment["FWF_UI_TEST_SHOW_FIRST_LAUNCH"] = "1"
        } else {
            // Skip the first-launch welcome sheet via a launch arg so it never
            // blocks interactions in tests that don't care about it.
            app.launchArguments += ["-HasShownFirstLaunch", "YES"]
        }

        if loggedIn, let accessToken, let accessTokenExpiry, let refreshToken, let userId {
            app.launchEnvironment["FWF_UI_TEST_ACCESS_TOKEN"] = accessToken
            app.launchEnvironment["FWF_UI_TEST_ACCESS_TOKEN_EXPIRY"] = accessTokenExpiry
            app.launchEnvironment["FWF_UI_TEST_REFRESH_TOKEN"] = refreshToken
            app.launchEnvironment["FWF_UI_TEST_USER_ID"] = userId
        }

        if let loginOutcome {
            app.launchEnvironment["FWF_UI_TEST_LOGIN_OUTCOME"] = loginOutcome
            // Do NOT inject token env vars for loginOutcome tests — the mock uses its own
            // built-in fallback token on success, and we need MockTokenManager.return_token
            // to be nil so the app starts on the WelcomeView (not already logged in).
        }

        setupSnapshot(app)
        app.launch()
    }

    // MARK: - Screenshot Helpers

    /// Take a screenshot and attach it to the test report
    func takeScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Backend API Helpers

    /// Make an authenticated HTTP request to the Docker backend
    @discardableResult
    func makeAuthenticatedRequest(method: String, path: String, body: [String: Any]? = nil) throws -> (Data, HTTPURLResponse) {
        guard let accessToken else {
            throw NSError(domain: "FWFUITest", code: 1, userInfo: [NSLocalizedDescriptionKey: "No access token available"])
        }

        let url = URL(string: "\(Self.backendBaseURL)/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        var responseData: Data?
        var httpResponse: HTTPURLResponse?
        var requestError: Error?

        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { data, response, error in
            responseData = data
            httpResponse = response as? HTTPURLResponse
            requestError = error
            semaphore.signal()
        }.resume()
        semaphore.wait()

        if let requestError {
            throw requestError
        }

        guard let responseData, let httpResponse else {
            throw NSError(domain: "FWFUITest", code: 2, userInfo: [NSLocalizedDescriptionKey: "No response from backend"])
        }

        return (responseData, httpResponse)
    }

    /// Create a test competition via the backend API and return the competition ID
    @discardableResult
    func createTestCompetition(name: String = "UI Test Competition") throws -> String {
        return try createCompetition(name: name, startDate: Date())
    }

    /// Create a competition starting `daysInPast` days ago, for screenshot tests that need
    /// accumulated historical activity data.
    @discardableResult
    func createCompetitionForScreenshots(name: String, daysInPast: Int = 5) throws -> String {
        let start = Date(timeIntervalSinceNow: -Double(daysInPast) * 24 * 60 * 60)
        return try createCompetition(name: name, startDate: start)
    }

    /// Seed a competition with realistic fake users for App Store screenshots.
    /// Each user gets the same activity values inserted for every day from the
    /// competition's start date through today, giving nonzero total points and points today.
    func seedCompetitionWithUsers(competitionId: String) throws {
        let users: [[String: Any]] = [
            ["firstName": "Alice",  "lastName": "Chen",
             "caloriesBurned": 420, "caloriesGoal": 400,
             "exerciseTime": 38,    "exerciseTimeGoal": 30,
             "standTime": 12,       "standTimeGoal": 12],
            ["firstName": "Marcus", "lastName": "Johnson",
             "caloriesBurned": 370, "caloriesGoal": 400,
             "exerciseTime": 32,    "exerciseTimeGoal": 30,
             "standTime": 11,       "standTimeGoal": 12],
            ["firstName": "Sarah",  "lastName": "Kim",
             "caloriesBurned": 240, "caloriesGoal": 400,
             "exerciseTime": 18,    "exerciseTimeGoal": 30,
             "standTime": 10,       "standTimeGoal": 12],
            ["firstName": "James",  "lastName": "Park",
             "caloriesBurned": 180, "caloriesGoal": 400,
             "exerciseTime": 14,    "exerciseTimeGoal": 30,
             "standTime": 8,        "standTimeGoal": 12],
        ]

        let url = URL(string: "http://localhost:3000/testHelpers/seedCompetitionUsers")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "competitionId": competitionId,
            "users": users
        ])

        var httpResponse: HTTPURLResponse?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { _, response, _ in
            httpResponse = response as? HTTPURLResponse
            semaphore.signal()
        }.resume()
        semaphore.wait()

        XCTAssertEqual(httpResponse?.statusCode, 200, "Failed to seed competition users")
    }

    /// Post activity data for the authenticated test user for every day from `daysAgo` days ago
    /// through today (inclusive).
    func seedSelfActivityData(daysAgo: Int,
                              caloriesBurned: Int, caloriesGoal: Int,
                              exerciseTime: Int, exerciseTimeGoal: Int,
                              standTime: Int, standTimeGoal: Int) throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        var summaries: [[String: Any]] = []
        for i in stride(from: daysAgo, through: 0, by: -1) {
            let date = Date(timeIntervalSinceNow: -Double(i) * 24 * 60 * 60)
            summaries.append([
                "date": formatter.string(from: date),
                "activeCaloriesBurned": caloriesBurned,
                "activeCaloriesGoal": caloriesGoal,
                "exerciseTime": exerciseTime,
                "exerciseTimeGoal": exerciseTimeGoal,
                "standTime": standTime,
                "standTimeGoal": standTimeGoal
            ])
        }

        try makeAuthenticatedRequest(method: "POST", path: "activityData/dailySummary",
                                     body: ["values": summaries])
    }

    /// Create a public competition via the admin endpoint and return the competition ID.
    @discardableResult
    func createPublicCompetition(name: String = "UI Test Public Competition") throws -> String {
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

    /// Make the test user a Pro subscriber via the test helpers endpoint
    func makeUserPro() throws {
        guard let userId else { return }

        let url = URL(string: "http://localhost:3000/testHelpers/setUserProStatus")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["userId": userId, "isPro": true]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        var httpResponse: HTTPURLResponse?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { _, response, _ in
            httpResponse = response as? HTTPURLResponse
            semaphore.signal()
        }.resume()
        semaphore.wait()

        XCTAssertEqual(httpResponse?.statusCode, 200, "Failed to make test user pro")
    }

    // MARK: - Private

    @discardableResult
    private func createCompetition(name: String, startDate: Date) throws -> String {
        let body: [String: Any] = [
            "displayName": name,
            "startDate": ISO8601DateFormatter().string(from: startDate),
            "endDate": ISO8601DateFormatter().string(from: Date(timeIntervalSinceNow: 7 * 24 * 60 * 60)),
            "ianaTimezone": TimeZone.current.identifier
        ]

        let (data, response) = try makeAuthenticatedRequest(method: "POST", path: "competitions", body: body)
        XCTAssertEqual(response.statusCode, 200, "Failed to create competition")

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return json["competition_id"] as! String
    }

    private func deleteAllCompetitions() {
        guard accessToken != nil else { return }
        if let (data, _) = try? makeAuthenticatedRequest(method: "GET", path: "competitions"),
           let competitionIds = try? JSONSerialization.jsonObject(with: data) as? [String] {
            for competitionId in competitionIds {
                try? makeAuthenticatedRequest(method: "POST", path: "competitions/delete", body: ["competitionId": competitionId])
            }
        }
    }

    private func checkBackendIsRunning() throws {
        let url = URL(string: Self.backendBaseURL)!
        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        var isRunning = false
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 500 {
                isRunning = true
            }
            semaphore.signal()
        }.resume()
        semaphore.wait()

        if !isRunning {
            throw XCTSkip("Docker backend is not running at \(Self.backendBaseURL). Run Scripts/start-ui-test-backend.sh first.")
        }
    }

    private func obtainAccessToken() throws {
        let url = URL(string: "\(Self.backendBaseURL)/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Self.basicAuthHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=refresh_token&refresh_token=UI_TEST_REFRESH_TOKEN".data(using: .utf8)

        var responseData: Data?
        var requestError: Error?

        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { data, _, error in
            responseData = data
            requestError = error
            semaphore.signal()
        }.resume()
        semaphore.wait()

        if let requestError {
            throw requestError
        }

        guard let responseData else {
            throw NSError(domain: "FWFUITest", code: 3, userInfo: [NSLocalizedDescriptionKey: "No response from token endpoint"])
        }

        let json = try JSONSerialization.jsonObject(with: responseData) as! [String: Any]
        guard let token = json["access_token"] as? String,
              let user = json["userId"] as? String else {
            let body = String(data: responseData, encoding: .utf8) ?? "nil"
            throw NSError(domain: "FWFUITest", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse token response: \(body)"])
        }

        accessToken = token
        userId = user
        refreshToken = "UI_TEST_REFRESH_TOKEN"

        // Parse expiry - the backend returns accessTokenExpiry as an ISO date string
        if let expiry = json["accessTokenExpiry"] as? String {
            accessTokenExpiry = expiry
        } else {
            // Fallback: set expiry to 1 hour from now
            accessTokenExpiry = ISO8601DateFormatter().string(from: Date(timeIntervalSinceNow: 3600))
        }
    }
}
