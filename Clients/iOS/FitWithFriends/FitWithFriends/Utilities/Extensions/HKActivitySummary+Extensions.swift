//
//  HKActivitySummary+Extensions.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import Foundation
import HealthKit

extension HKActivitySummary {
    convenience init(activeEnergyBurned: Double,
                     activeEnergyBurnedGoal: Double,
                     exerciseTime: Double,
                     exerciseTimeGoal: Double,
                     standTime: Double,
                     standTimeGoal: Double) {
        self.init()

        self.activeEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: activeEnergyBurned)
        self.activeEnergyBurnedGoal = HKQuantity(unit: .kilocalorie(), doubleValue: activeEnergyBurnedGoal)
        self.appleExerciseTime = HKQuantity(unit: .minute(), doubleValue: exerciseTime)
        self.appleExerciseTimeGoal = HKQuantity(unit: .minute(), doubleValue: exerciseTimeGoal)
        self.appleStandHours = HKQuantity(unit: .count(), doubleValue: standTime)
        self.appleStandHoursGoal = HKQuantity(unit: .count(), doubleValue: standTimeGoal)
    }
}
