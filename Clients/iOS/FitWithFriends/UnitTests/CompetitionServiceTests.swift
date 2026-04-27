//
//  CompetitionServiceTests.swift
//  FitWithFriends
//
//  Verifies the wire shape of CompetitionService.createCompetition. Specifically: the request
//  body must omit `scoringRules` for the default rule (otherwise the server-side Pro gate would
//  reject free users) and must include the rule for any custom config.
//

import XCTest
@testable import Fit_with_Friends

final class CompetitionServiceTests: XCTestCase {
    private var service: CompetitionService!
    private var mockHttpConnector: MockHttpConnector!
    private var mockTokenManager: MockTokenManager!
    private var mockServerEnvironmentManager: MockServerEnvironmentManager!

    override func setUp() {
        super.setUp()
        mockHttpConnector = MockHttpConnector()
        mockTokenManager = MockTokenManager()
        mockServerEnvironmentManager = MockServerEnvironmentManager()

        // Authenticated path requires a valid token in the manager.
        mockTokenManager.return_token = Token(
            accessToken: "tok",
            accessTokenExpiry: Date(timeIntervalSinceNow: 3600),
            refreshToken: nil,
            userId: "user"
        )
        mockHttpConnector.return_data = EmptyResponse()

        service = CompetitionService(
            httpConnector: mockHttpConnector,
            serverEnvironmentManager: mockServerEnvironmentManager,
            tokenManager: mockTokenManager
        )
    }

    override func tearDown() {
        service = nil
        mockHttpConnector = nil
        mockTokenManager = nil
        mockServerEnvironmentManager = nil
        super.tearDown()
    }

    /// Re-encode the captured Encodable body so we can inspect the JSON the server will see.
    private func capturedBodyJSON() throws -> [String: Any] {
        let body = try XCTUnwrap(mockHttpConnector.param_body)
        let data = try JSONEncoder.fwfDefaultEncoder.encode(AnyEncodable(body))
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return json
    }

    func test_createCompetition_defaultRule_omitsScoringRulesField() async throws {
        try await service.createCompetition(
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 86400),
            competitionName: "Default Comp",
            scoringRules: .default
        )

        let json = try capturedBodyJSON()
        XCTAssertEqual(json["displayName"] as? String, "Default Comp")
        // Critical: omitting the field is what allows free users to create competitions —
        // any explicit value here would trip the server's Pro gate.
        XCTAssertNil(json["scoringRules"], "scoringRules must be omitted for the default rule")
    }

    func test_createCompetition_workoutsRule_includesScoringRulesPayload() async throws {
        try await service.createCompetition(
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 86400),
            competitionName: "Distance Comp",
            scoringRules: .workouts(metric: .distance, activityTypes: [37])
        )

        let json = try capturedBodyJSON()
        let rules = try XCTUnwrap(json["scoringRules"] as? [String: Any])
        XCTAssertEqual(rules["kind"] as? String, "workouts")
        XCTAssertEqual(rules["metric"] as? String, "distance")
        XCTAssertEqual(rules["activityTypes"] as? [Int], [37])
    }

    func test_createCompetition_customRingsRule_includesScoringRulesPayload() async throws {
        let rule: ScoringRules = .rings(
            includedRings: [.calories, .exercise],
            minGoals: RingMinGoals(calories: 500),
            dailyCap: 350
        )
        try await service.createCompetition(
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 86400),
            competitionName: "Custom Rings",
            scoringRules: rule
        )

        let json = try capturedBodyJSON()
        let rules = try XCTUnwrap(json["scoringRules"] as? [String: Any])
        XCTAssertEqual(rules["kind"] as? String, "rings")
        XCTAssertEqual(rules["dailyCap"] as? Int, 350)
        let includedRings = try XCTUnwrap(rules["includedRings"] as? [String])
        XCTAssertEqual(Set(includedRings), Set(["calories", "exercise"]))
    }

    func test_createCompetition_dailyRule_includesScoringRulesPayload() async throws {
        try await service.createCompetition(
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 86400),
            competitionName: "Steps",
            scoringRules: .daily(metric: .steps)
        )

        let json = try capturedBodyJSON()
        let rules = try XCTUnwrap(json["scoringRules"] as? [String: Any])
        XCTAssertEqual(rules["kind"] as? String, "daily")
        XCTAssertEqual(rules["metric"] as? String, "steps")
    }
}

/// Type-erased Encodable wrapper so we can re-encode the captured `Encodable?` from the mock
/// connector without knowing its concrete type at the call site.
private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ wrapped: Encodable) {
        self.encodeFunc = wrapped.encode
    }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}
