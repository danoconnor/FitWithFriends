//
//  CompetitionWireFormatTests.swift
//  FitWithFriends
//
//  Decoding tests pinned to the on-the-wire JSON the backend emits today, plus
//  legacy-server fallbacks (omitted scoringRules / scoringUnit / value).
//

import XCTest
@testable import Fit_with_Friends

final class CompetitionWireFormatTests: XCTestCase {

    /// Uses the same decoder configuration as the networking layer so dates parse identically
    /// to production responses.
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        return try JSONDecoder.fwfDefaultDecoder.decode(T.self, from: Data(json.utf8))
    }

    // MARK: - CompetitionOverview

    func testCompetitionOverview_decodesNewFields() throws {
        let json = """
        {
            "competitionId": "11111111-1111-1111-1111-111111111111",
            "competitionName": "Steps Challenge",
            "competitionStart": "2026-04-01T00:00:00.000Z",
            "competitionEnd": "2026-04-08T00:00:00.000Z",
            "currentResults": [],
            "competitionState": 1,
            "isPublic": false,
            "isUserAdmin": true,
            "scoringRules": { "kind": "daily", "metric": "steps" },
            "scoringUnit": "steps"
        }
        """
        let overview = try decode(CompetitionOverview.self, json)
        XCTAssertEqual(overview.scoringUnit, .steps)
        guard case let .daily(metric) = overview.scoringRules else {
            return XCTFail("expected .daily rule")
        }
        XCTAssertEqual(metric, .steps)
    }

    func testCompetitionOverview_legacyServer_omitsScoringFields_fallsBackToDefaults() throws {
        // Older server response: no scoringRules, no scoringUnit. Must still decode and
        // give the legacy rings/points behaviour so the leaderboard renders unchanged.
        let json = """
        {
            "competitionId": "22222222-2222-2222-2222-222222222222",
            "competitionName": "Legacy Comp",
            "competitionStart": "2026-04-01T00:00:00.000Z",
            "competitionEnd": "2026-04-08T00:00:00.000Z",
            "currentResults": [],
            "competitionState": 1,
            "isPublic": false,
            "isUserAdmin": false
        }
        """
        let overview = try decode(CompetitionOverview.self, json)
        XCTAssertTrue(overview.scoringRules.isDefault)
        XCTAssertEqual(overview.scoringUnit, .points)
    }

    func testCompetitionOverview_codableRoundTrip_preservesScoringConfig() throws {
        let original = CompetitionOverview(
            id: UUID(),
            name: "Round Trip",
            start: Date(timeIntervalSince1970: 1_700_000_000),
            end: Date(timeIntervalSince1970: 1_700_604_800),
            currentResults: [],
            isUserAdmin: true,
            competitionState: .notStartedOrActive,
            isPublic: true,
            scoringRules: .workouts(metric: .duration, activityTypes: [37]),
            scoringUnit: .minutes
        )
        let data = try JSONEncoder.fwfDefaultEncoder.encode(original)
        let decoded = try JSONDecoder.fwfDefaultDecoder.decode(CompetitionOverview.self, from: data)
        guard case let .workouts(metric, types) = decoded.scoringRules else {
            return XCTFail("expected workouts rule")
        }
        XCTAssertEqual(metric, .duration)
        XCTAssertEqual(types, [37])
        XCTAssertEqual(decoded.scoringUnit, .minutes)
    }

    // MARK: - UserCompetitionDailyDetails

    func testUserCompetitionDailyDetails_legacyServer_defaultsScoringUnitToPoints() throws {
        // Older server omits scoringUnit; iOS must default to .points to keep the rings UI working.
        let json = """
        {
            "userId": "abc",
            "firstName": "A",
            "lastName": "B",
            "competitionId": "33333333-3333-3333-3333-333333333333",
            "dailySummaries": []
        }
        """
        let details = try decode(UserCompetitionDailyDetails.self, json)
        XCTAssertEqual(details.scoringUnit, .points)
    }

    func testUserCompetitionDailyDetails_decodesScoringUnit() throws {
        let json = """
        {
            "userId": "abc",
            "firstName": "A",
            "lastName": "B",
            "competitionId": "44444444-4444-4444-4444-444444444444",
            "dailySummaries": [],
            "scoringUnit": "meters"
        }
        """
        let details = try decode(UserCompetitionDailyDetails.self, json)
        XCTAssertEqual(details.scoringUnit, .meters)
    }

    // MARK: - DailySummary value vs points

    func testDailySummary_prefersValueOverPoints() throws {
        // Server sends both `value` (rule-aware) and `points` (legacy alias). When both are
        // present, iOS should honour `value` so non-rings rules display correct totals.
        let json = """
        {
            "date": "2026-04-15T00:00:00.000Z",
            "caloriesBurned": 0, "caloriesGoal": 0,
            "exerciseTime": 0, "exerciseTimeGoal": 0,
            "standTime": 0, "standTimeGoal": 0,
            "stepCount": 0, "distanceWalkingRunningMeters": 0,
            "value": 8500,
            "points": 999
        }
        """
        let summary = try decode(DailySummary.self, json)
        XCTAssertEqual(summary.points, 8500)
    }

    func testDailySummary_fallsBackToPointsWhenValueMissing() throws {
        // Older server only sends `points`. Decoder should still surface that.
        let json = """
        {
            "date": "2026-04-15T00:00:00.000Z",
            "caloriesBurned": 100, "caloriesGoal": 400,
            "exerciseTime": 10, "exerciseTimeGoal": 30,
            "standTime": 5, "standTimeGoal": 12,
            "points": 75
        }
        """
        let summary = try decode(DailySummary.self, json)
        XCTAssertEqual(summary.points, 75)
        // Legacy payload omits step/distance — defaults apply.
        XCTAssertEqual(summary.stepCount, 0)
        XCTAssertEqual(summary.distanceWalkingRunningMeters, 0)
    }

    func testDailySummary_decodesNewDailyMetricFields() throws {
        let json = """
        {
            "date": "2026-04-15T00:00:00.000Z",
            "caloriesBurned": 0, "caloriesGoal": 0,
            "exerciseTime": 0, "exerciseTimeGoal": 0,
            "standTime": 0, "standTimeGoal": 0,
            "stepCount": 8500,
            "distanceWalkingRunningMeters": 4200,
            "value": 8500
        }
        """
        let summary = try decode(DailySummary.self, json)
        XCTAssertEqual(summary.stepCount, 8500)
        XCTAssertEqual(summary.distanceWalkingRunningMeters, 4200)
    }
}
