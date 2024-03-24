//
//  ActivitySummary.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/29/20.
//

import Foundation
import HealthKit

class ActivitySummary: IdentifiableBase, Codable {
    let date: Date
    private(set) var activeCaloriesBurned: Double
    private(set) var activeCaloriesGoal: Double
    private(set) var exerciseTime: Double
    private(set) var exerciseTimeGoal: Double
    private(set) var standTime: Double
    private(set) var standTimeGoal: Double
    private(set) var distanceWalkingRunning: Double?
    private(set) var stepCount: UInt?
    private(set) var flightsClimbed: UInt?

    private(set) var activitySummary: HKActivitySummary?

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

    /// Creates an empty `ActivitySummary` for the given date
    init(date: Date) {
        self.date = date

        self.activeCaloriesBurned = 0
        self.activeCaloriesGoal = 0
        self.exerciseTime = 0
        self.exerciseTimeGoal = 0
        self.standTime = 0
        self.standTimeGoal = 0
    }

    /// Creates an `ActivitySummary` for the given date with zero progress towards any of the given goals
    init(date: Date, calorieGoal: Double, exerciseGoal: Double, standGoal: Double) {
        self.date = date

        activeCaloriesBurned = 0
        activeCaloriesGoal = calorieGoal
        exerciseTime = 0
        exerciseTimeGoal = exerciseGoal
        standTime = 0
        standTimeGoal = standGoal
    }

    /// Creates an `ActivitySummary` based on the summary returned by Apple HealthKit
    init?(activitySummary: HKActivitySummary) {
        guard let activityDate = activitySummary.dateComponents(for: Calendar.current).date else {
            Logger.traceError(message: "Tried to initialize ActivitySummary without valid date")
            return nil
        }

        date = activityDate
        activeCaloriesBurned = round(activitySummary.activeEnergyBurned.doubleValue(for: .largeCalorie()))
        activeCaloriesGoal = round(activitySummary.activeEnergyBurnedGoal.doubleValue(for: .largeCalorie()))
        exerciseTime = round(activitySummary.appleExerciseTime.doubleValue(for: .minute()))
        exerciseTimeGoal = round(activitySummary.appleExerciseTimeGoal.doubleValue(for: .minute()))
        standTime = round(activitySummary.appleStandHours.doubleValue(for: .count()))
        standTimeGoal = round(activitySummary.appleStandHoursGoal.doubleValue(for: .count()))

        self.activitySummary = activitySummary
    }

    func updateStatistic(quantityType: HKQuantityTypeIdentifier, value: HKStatistics) {
        switch quantityType {
        case .activeEnergyBurned:
            activeCaloriesBurned = value.sumQuantity()?.doubleValue(for: .largeCalorie()) ?? 0
        case .appleExerciseTime:
            exerciseTime = value.sumQuantity()?.doubleValue(for: .minute()) ?? 0
        case .appleStandTime:
            // Convert min to hours
            standTime = (value.sumQuantity()?.doubleValue(for: .minute()) ?? 0) / 60
        case .distanceWalkingRunning:
            distanceWalkingRunning = value.sumQuantity()?.doubleValue(for: .meter())
        case .stepCount:
            stepCount = UInt(round(value.sumQuantity()?.doubleValue(for: .count()) ?? 0))
        case .flightsClimbed:
            flightsClimbed = UInt(round(value.sumQuantity()?.doubleValue(for: .count()) ?? 0))
        default:
            Logger.traceError(message: "Unexpected quantity type: \(String(describing: quantityType))")
        }
    }
}

extension ActivitySummary {
    /// This is an estimate of the points that this activity summary will provide
    /// The real source of truth comes from the service in the CompetitionOverview entity
    var competitionPoints: Double {
        let caloriePoints = activeCaloriesGoal > 0 ? activeCaloriesBurned / activeCaloriesGoal * 100 : 0
        let exercisePoints = exerciseTimeGoal > 0 ? exerciseTime / exerciseTimeGoal * 100 : 0
        let standPoints = standTimeGoal > 0 ? standTime / standTimeGoal * 100 : 0
        let totalPoints = caloriePoints + exercisePoints + standPoints

        // Apple's competition scoring has a maximum of 600 pts/day
        return min(600, totalPoints)
    }
}
