//
//  HKActivitySummary+Extensions.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import Foundation
import HealthKit

extension HKActivitySummary {
    var competitionPoints: Double {
        let caloriePoints = activeEnergyBurned.doubleValue(for: .kilocalorie()) / activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()) * 100
        let exercisePoints = appleExerciseTime.doubleValue(for: .minute()) / appleExerciseTimeGoal.doubleValue(for: .minute()) * 100
        let standPoints = appleStandHours.doubleValue(for: .count()) / appleStandHoursGoal.doubleValue(for: .count()) * 100
        let totalPoints = caloriePoints + exercisePoints + standPoints

        // Apple's competition scoring has a maximum of 600 pts/day
        return min(600, totalPoints)
    }
}
