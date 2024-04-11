//
//  ActivitySummary.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/29/20.
//

import Foundation
import HealthKit

public class ActivitySummary: IdentifiableBase, Encodable {
    public let date: Date

    public let activeCaloriesGoal: UInt
    public let exerciseTimeGoal: UInt
    public let standTimeGoal: UInt

    public private(set) var activeCaloriesBurned: UInt
    public private(set) var exerciseTime: UInt
    public private(set) var standTime: UInt
    public private(set) var distanceWalkingRunning: UInt?
    public private(set) var stepCount: UInt?
    public private(set) var flightsClimbed: UInt?

    /// Expose the underlying HKActivitySummary since we need it to use Apple's built in UI
    /// for displaying the health rings
    public let hkActivitySummary: HKActivitySummary

    enum CodingKeys: String, CodingKey {
        case date
        case activeCaloriesBurned
        case activeCaloriesGoal
        case exerciseTime
        case exerciseTimeGoal
        case standTime
        case standTimeGoal
        case distanceWalkingRunning
        case stepCount
        case flightsClimbed
    }

    /// Creates an `ActivitySummary` based on the summary returned by Apple HealthKit
    public init(activitySummary: ActivitySummaryDTO) {
        date = activitySummary.date
        activeCaloriesBurned = activitySummary.activeEnergyBurned
        activeCaloriesGoal = activitySummary.activeEnergyBurnedGoal
        exerciseTime = activitySummary.appleExerciseTime
        exerciseTimeGoal = activitySummary.appleExerciseTimeGoal
        standTime = activitySummary.appleStandHours
        standTimeGoal = activitySummary.appleStandHoursGoal

        self.hkActivitySummary = activitySummary.hkActivitySummary
    }

    public func updateStatistic(quantityType: HKQuantityTypeIdentifier, value: StatisticDTO) {
        switch quantityType {
        case .activeEnergyBurned:
            activeCaloriesBurned = value.sumValue
        case .appleExerciseTime:
            exerciseTime = value.sumValue
        case .appleStandTime:
            // Convert min to hours
            standTime = value.sumValue
        case .distanceWalkingRunning:
            distanceWalkingRunning = value.sumValue
        case .stepCount:
            stepCount = value.sumValue
        case .flightsClimbed:
            flightsClimbed = value.sumValue
        default:
            Logger.traceError(message: "Unexpected quantity type: \(String(describing: quantityType))")
        }
    }
}

extension ActivitySummary {
    /// This is an estimate of the points that this activity summary will provide
    /// The real source of truth comes from the service in the CompetitionOverview entity
    public var competitionPoints: Double {
        let caloriePoints = activeCaloriesGoal > 0 ? Double(activeCaloriesBurned) / Double(activeCaloriesGoal) * 100 : 0
        let exercisePoints = exerciseTimeGoal > 0 ? Double(exerciseTime) / Double(exerciseTimeGoal) * 100 : 0
        let standPoints = standTimeGoal > 0 ? Double(standTime) / Double(standTimeGoal) * 100 : 0
        let totalPoints = caloriePoints + exercisePoints + standPoints

        // Apple's competition scoring has a maximum of 600 pts/day
        return min(600, totalPoints)
    }
}
