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
    let activeCaloriesBurned: Double
    let activeCaloriesGoal: Double
    let exerciseTime: Double
    let exerciseTimeGoal: Double
    let standTime: Double
    let standTimeGoal: Double

    var activitySummary: HKActivitySummary?

    enum CodingKeys: String, CodingKey {
        case date
        case activeCaloriesBurned
        case activeCaloriesGoal
        case exerciseTime
        case exerciseTimeGoal
        case standTime
        case standTimeGoal
    }

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
}

extension ActivitySummary {
    /// This is an estimate of the points that this activity summary will provide
    /// The real source of truth comes from the service in the CompetitionOverview entity
    var competitionPoints: Double {
        let caloriePoints = activeCaloriesBurned / activeCaloriesGoal * 100
        let exercisePoints = exerciseTime / exerciseTimeGoal * 100
        let standPoints = standTime / standTimeGoal * 100
        let totalPoints = caloriePoints + exercisePoints + standPoints

        // Apple's competition scoring has a maximum of 600 pts/day
        return min(600, totalPoints)
    }
}
