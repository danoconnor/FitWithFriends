//
//  ScoringRulesTests.swift
//  FitWithFriends
//

import XCTest
@testable import Fit_with_Friends

final class ScoringRulesTests: XCTestCase {

    // MARK: - Round-trip Codable

    func testRingsDefaultRoundtrip() throws {
        let encoded = try JSONEncoder().encode(ScoringRules.default)
        let decoded = try JSONDecoder().decode(ScoringRules.self, from: encoded)
        XCTAssertTrue(decoded.isDefault)
    }

    func testRingsWithMinGoalsAndDailyCapRoundtrip() throws {
        let rule: ScoringRules = .rings(
            includedRings: [.calories, .exercise],
            minGoals: RingMinGoals(calories: 500, exerciseTime: 30, standTime: nil),
            dailyCap: 400
        )

        let encoded = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(ScoringRules.self, from: encoded)
        guard case let .rings(rings, goals, cap) = decoded else { return XCTFail("Wrong case") }
        XCTAssertEqual(rings, [.calories, .exercise])
        XCTAssertEqual(goals?.calories, 500)
        XCTAssertEqual(goals?.exerciseTime, 30)
        XCTAssertNil(goals?.standTime)
        XCTAssertEqual(cap, 400)
    }

    func testWorkoutsRuleRoundtrip() throws {
        let rule: ScoringRules = .workouts(metric: .distance, activityTypes: [37, 52])
        let encoded = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(ScoringRules.self, from: encoded)
        guard case let .workouts(metric, types) = decoded else { return XCTFail("Wrong case") }
        XCTAssertEqual(metric, .distance)
        XCTAssertEqual(types, [37, 52])
    }

    func testDailyRuleRoundtrip() throws {
        let rule: ScoringRules = .daily(metric: .steps)
        let encoded = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(ScoringRules.self, from: encoded)
        guard case let .daily(metric) = decoded else { return XCTFail("Wrong case") }
        XCTAssertEqual(metric, .steps)
    }

    // MARK: - Server shape decoding

    func testDecodesServerRingsWithNoIncludedRings() throws {
        // Server may omit includedRings — default to all rings
        let json = Data(#"{"kind":"rings"}"#.utf8)
        let decoded = try JSONDecoder().decode(ScoringRules.self, from: json)
        guard case let .rings(rings, _, _) = decoded else { return XCTFail("Wrong case") }
        XCTAssertEqual(rings, Set(ScoringRing.allCases))
    }

    func testDecodesServerWorkoutsWithoutActivityTypes() throws {
        let json = Data(#"{"kind":"workouts","metric":"calories"}"#.utf8)
        let decoded = try JSONDecoder().decode(ScoringRules.self, from: json)
        guard case let .workouts(metric, types) = decoded else { return XCTFail("Wrong case") }
        XCTAssertEqual(metric, .calories)
        XCTAssertNil(types)
    }

    // MARK: - Unit derivation

    func testDeriveUnitForEachRuleKind() {
        XCTAssertEqual(ScoringUnit.derive(from: .rings(includedRings: [.calories], minGoals: nil, dailyCap: nil)), .points)
        XCTAssertEqual(ScoringUnit.derive(from: .workouts(metric: .calories, activityTypes: nil)), .kcal)
        XCTAssertEqual(ScoringUnit.derive(from: .workouts(metric: .duration, activityTypes: nil)), .minutes)
        XCTAssertEqual(ScoringUnit.derive(from: .workouts(metric: .distance, activityTypes: nil)), .meters)
        XCTAssertEqual(ScoringUnit.derive(from: .daily(metric: .steps)), .steps)
        XCTAssertEqual(ScoringUnit.derive(from: .daily(metric: .walkingRunningDistance)), .meters)
    }

    // MARK: - isDefault

    func testDefaultPredicateTrueOnlyForStandardRings() {
        XCTAssertTrue(ScoringRules.default.isDefault)
        XCTAssertFalse(ScoringRules.rings(includedRings: [.calories], minGoals: nil, dailyCap: nil).isDefault)
        XCTAssertFalse(ScoringRules.rings(includedRings: Set(ScoringRing.allCases), minGoals: RingMinGoals(calories: 500), dailyCap: nil).isDefault)
        XCTAssertFalse(ScoringRules.rings(includedRings: Set(ScoringRing.allCases), minGoals: nil, dailyCap: 400).isDefault)
        XCTAssertFalse(ScoringRules.workouts(metric: .distance, activityTypes: nil).isDefault)
    }

    // MARK: - Formatter

    func testFormatterPoints() {
        XCTAssertEqual(ScoringValueFormatter.format(123, unit: .points), "123 pts")
        XCTAssertEqual(ScoringValueFormatter.format(1234, unit: .points), "1,234 pts")
        XCTAssertEqual(ScoringValueFormatter.formatCompact(123, unit: .points), "123")
    }

    func testFormatterSteps() {
        XCTAssertEqual(ScoringValueFormatter.format(45678, unit: .steps), "45,678 steps")
    }

    func testFormatterCalories() {
        XCTAssertEqual(ScoringValueFormatter.format(2500, unit: .kcal), "2,500 kcal")
    }

    func testFormatterMinutes() {
        XCTAssertEqual(ScoringValueFormatter.format(45, unit: .minutes), "45 min")
    }
}
