//
//  WatchUITestBase.swift
//  FitWithFriends Watch App UITests
//
//  Base class for Watch UI tests. Mirrors FWFUITestBase but targets the Watch app.
//  Connects to the Docker backend at localhost:3000 to seed test data, then launches
//  the Watch app with injected tokens via environment variables.
//

import XCTest

class WatchUITestBase: XCTestCase {
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

        try checkBackendIsRunning()
        try obtainAccessToken()
        deleteAllCompetitions()
    }

    override func tearDownWithError() throws {
        deleteAllCompetitions()
    }

    // MARK: - App Launch Helpers

    /// Launch the Watch app in UI testing mode.
    /// - Parameter loggedIn: If true, inject access token so the app starts in logged-in state.
    func launchApp(loggedIn: Bool = true) {
        app = XCUIApplication()
        app.launchEnvironment["FWF_UI_TESTING"] = "1"

        if loggedIn, let accessToken, let accessTokenExpiry, let refreshToken, let userId {
            app.launchEnvironment["FWF_UI_TEST_ACCESS_TOKEN"] = accessToken
            app.launchEnvironment["FWF_UI_TEST_ACCESS_TOKEN_EXPIRY"] = accessTokenExpiry
            app.launchEnvironment["FWF_UI_TEST_REFRESH_TOKEN"] = refreshToken
            app.launchEnvironment["FWF_UI_TEST_USER_ID"] = userId
        }

        app.launch()
    }

    // MARK: - Element Query Helpers

    /// Find a competition card button whose label contains the given name.
    /// On watchOS, NavigationLink collapses child Text elements into the parent
    /// Button's label, so individual StaticText queries won't work.
    func competitionCard(named name: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        return app.buttons.matching(predicate).firstMatch
    }

    // MARK: - Screenshot Helpers

    func takeScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Backend API Helpers

    @discardableResult
    func makeAuthenticatedRequest(method: String, path: String, body: [String: Any]? = nil) throws -> (Data, HTTPURLResponse) {
        guard let accessToken else {
            throw NSError(domain: "WatchUITest", code: 1, userInfo: [NSLocalizedDescriptionKey: "No access token available"])
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
            throw NSError(domain: "WatchUITest", code: 2, userInfo: [NSLocalizedDescriptionKey: "No response from backend"])
        }

        return (responseData, httpResponse)
    }

    @discardableResult
    func createTestCompetition(name: String = "Watch UI Test Competition") throws -> String {
        return try createCompetition(name: name, startDate: Date())
    }

    @discardableResult
    func createCompetitionWithHistory(name: String, daysInPast: Int = 5) throws -> String {
        let start = Date(timeIntervalSinceNow: -Double(daysInPast) * 24 * 60 * 60)
        return try createCompetition(name: name, startDate: start)
    }

    @discardableResult
    func seedCompetitionWithUsers(competitionId: String) throws -> [String] {
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

        var responseData: Data?
        var httpResponse: HTTPURLResponse?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { data, response, _ in
            responseData = data
            httpResponse = response as? HTTPURLResponse
            semaphore.signal()
        }.resume()
        semaphore.wait()

        XCTAssertEqual(httpResponse?.statusCode, 200, "Failed to seed competition users")

        if let data = responseData,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let userIds = json["userIds"] as? [String] {
            return userIds
        }
        return []
    }

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
        // Retry a few times — on CI the backend may still be starting up
        for attempt in 1...5 {
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

            if isRunning { return }

            if attempt < 5 {
                Thread.sleep(forTimeInterval: 2)
            }
        }

        throw XCTSkip("Docker backend is not running at \(Self.backendBaseURL). Run Scripts/start-ui-test-backend.sh first.")
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
            throw NSError(domain: "WatchUITest", code: 3, userInfo: [NSLocalizedDescriptionKey: "No response from token endpoint"])
        }

        let json = try JSONSerialization.jsonObject(with: responseData) as! [String: Any]
        guard let token = json["access_token"] as? String,
              let user = json["userId"] as? String else {
            let body = String(data: responseData, encoding: .utf8) ?? "nil"
            throw NSError(domain: "WatchUITest", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse token response: \(body)"])
        }

        accessToken = token
        userId = user
        refreshToken = "UI_TEST_REFRESH_TOKEN"

        if let expiry = json["accessTokenExpiry"] as? String {
            accessTokenExpiry = expiry
        } else {
            accessTokenExpiry = ISO8601DateFormatter().string(from: Date(timeIntervalSinceNow: 3600))
        }
    }
}
