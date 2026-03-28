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
    /// - Parameter loggedIn: If true, inject access token so the app starts in logged-in state
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
        let startDate = ISO8601DateFormatter().string(from: Date())
        let endDate = ISO8601DateFormatter().string(from: Date(timeIntervalSinceNow: 7 * 24 * 60 * 60))

        let body: [String: Any] = [
            "displayName": name,
            "startDate": startDate,
            "endDate": endDate,
            "ianaTimezone": TimeZone.current.identifier
        ]

        let (data, response) = try makeAuthenticatedRequest(method: "POST", path: "competitions", body: body)
        XCTAssertEqual(response.statusCode, 200, "Failed to create test competition")

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return json["competition_id"] as! String
    }

    // MARK: - Private

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
