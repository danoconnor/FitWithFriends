//
//  DailySummary.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/9/26.
//

import Foundation

public class DailySummary: IdentifiableBase, Codable {
    enum CodingKeys: String, CodingKey {
        case date
        case caloriesBurned
        case caloriesGoal
        case exerciseTime
        case exerciseTimeGoal
        case standTime
        case standTimeGoal
        case stepCount
        case distanceWalkingRunningMeters
        case value
        case points
    }

    let date: Date
    /// Ring-rule fields. Zero when the competition uses a non-rings rule.
    let caloriesBurned: UInt
    let caloriesGoal: UInt
    let exerciseTime: UInt
    let exerciseTimeGoal: UInt
    let standTime: UInt
    let standTimeGoal: UInt
    /// Daily-rule fields. Zero when the competition uses a rings or workouts rule.
    let stepCount: UInt
    let distanceWalkingRunningMeters: UInt
    /// Rule-aware per-day score, always in the competition's scoring unit.
    /// `points` is kept as an alias for back-compat with ring-based UI.
    let points: Double

    init(date: Date = Date(),
         caloriesBurned: UInt = 0, caloriesGoal: UInt = 400,
         exerciseTime: UInt = 0, exerciseTimeGoal: UInt = 30,
         standTime: UInt = 0, standTimeGoal: UInt = 12,
         stepCount: UInt = 0, distanceWalkingRunningMeters: UInt = 0,
         points: Double = 0) {
        self.date = date
        self.caloriesBurned = caloriesBurned
        self.caloriesGoal = caloriesGoal
        self.exerciseTime = exerciseTime
        self.exerciseTimeGoal = exerciseTimeGoal
        self.standTime = standTime
        self.standTimeGoal = standTimeGoal
        self.stepCount = stepCount
        self.distanceWalkingRunningMeters = distanceWalkingRunningMeters
        self.points = points
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        caloriesBurned = try container.decodeIfPresent(UInt.self, forKey: .caloriesBurned) ?? 0
        caloriesGoal = try container.decodeIfPresent(UInt.self, forKey: .caloriesGoal) ?? 0
        exerciseTime = try container.decodeIfPresent(UInt.self, forKey: .exerciseTime) ?? 0
        exerciseTimeGoal = try container.decodeIfPresent(UInt.self, forKey: .exerciseTimeGoal) ?? 0
        standTime = try container.decodeIfPresent(UInt.self, forKey: .standTime) ?? 0
        standTimeGoal = try container.decodeIfPresent(UInt.self, forKey: .standTimeGoal) ?? 0
        stepCount = try container.decodeIfPresent(UInt.self, forKey: .stepCount) ?? 0
        distanceWalkingRunningMeters = try container.decodeIfPresent(UInt.self, forKey: .distanceWalkingRunningMeters) ?? 0
        // Prefer `value` (newer, rule-aware field) then fall back to legacy `points`
        let value = try container.decodeIfPresent(Double.self, forKey: .value)
        let points = try container.decodeIfPresent(Double.self, forKey: .points)
        self.points = value ?? points ?? 0
        super.init()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(caloriesBurned, forKey: .caloriesBurned)
        try container.encode(caloriesGoal, forKey: .caloriesGoal)
        try container.encode(exerciseTime, forKey: .exerciseTime)
        try container.encode(exerciseTimeGoal, forKey: .exerciseTimeGoal)
        try container.encode(standTime, forKey: .standTime)
        try container.encode(standTimeGoal, forKey: .standTimeGoal)
        try container.encode(stepCount, forKey: .stepCount)
        try container.encode(distanceWalkingRunningMeters, forKey: .distanceWalkingRunningMeters)
        try container.encode(points, forKey: .points)
    }
}
