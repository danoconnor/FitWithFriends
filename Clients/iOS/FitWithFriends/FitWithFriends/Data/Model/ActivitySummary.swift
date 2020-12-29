//
//  ActivitySummary.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/29/20.
//

import Foundation
import HealthKit

class ActivitySummary: Codable {
    let date: Date
    let activeCaloriesBurned: Double
    let activeCaloriesGoal: Double
    let exerciseTime: Double
    let exerciseTimeGoal: Double
    let moveTime: Double
    let moveTimeGoal: Double
    let standTime: Double
    let standTimeGoal: Double

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
        moveTime = round(activitySummary.appleMoveTime.doubleValue(for: .minute()))
        moveTimeGoal = round(activitySummary.appleMoveTimeGoal.doubleValue(for: .minute()))
        standTime = round(activitySummary.appleStandHours.doubleValue(for: .count()))
        standTimeGoal = round(activitySummary.appleStandHoursGoal.doubleValue(for: .count()))
    }
}
