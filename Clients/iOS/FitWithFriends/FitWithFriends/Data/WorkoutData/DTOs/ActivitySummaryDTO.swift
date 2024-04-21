//
//  ActivitySummaryDTO.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/6/24.
//

import Foundation
import HealthKit

/// Translates from the HealthKit HKActivitySummary class
public struct ActivitySummaryDTO {
    public let date: Date

    public let activeEnergyBurned: UInt
    public let activeEnergyBurnedGoal: UInt

    public let appleExerciseTime: UInt
    public let appleExerciseTimeGoal: UInt

    public let appleStandHours: UInt
    public let appleStandHoursGoal: UInt

    /// Expose the underlying HKActivitySummary since we need it to use Apple's built in UI
    /// for displaying the health rings
    public let hkActivitySummary: HKActivitySummary

    public init?(hkActivitySummary: HKActivitySummary) {
        guard let date = hkActivitySummary.dateComponents(for: Calendar.current).date else {
            Logger.traceError(message: "Tried to initialize ActivitySummaryDTO without valid date")
            return nil
        }

        self.date = date

        activeEnergyBurned = UInt(round(hkActivitySummary.activeEnergyBurned.doubleValue(for: .largeCalorie())))
        activeEnergyBurnedGoal = UInt(round(hkActivitySummary.activeEnergyBurnedGoal.doubleValue(for: .largeCalorie())))
        appleExerciseTime = UInt(round(hkActivitySummary.appleExerciseTime.doubleValue(for: .minute())))
        appleExerciseTimeGoal = UInt(round(hkActivitySummary.appleExerciseTimeGoal.doubleValue(for: .minute())))

        appleStandHours = UInt(round(hkActivitySummary.appleStandHours.doubleValue(for: .count())))
        appleStandHoursGoal = UInt(round(hkActivitySummary.appleStandHoursGoal.doubleValue(for: .count())))

        self.hkActivitySummary = hkActivitySummary
    }

    /// Initializer for unit tests, not used in production code
    public init(date: Date,
         activeEnergyBurned: UInt,
         activeEnergyBurnedGoal: UInt,
         appleExerciseTime: UInt,
         appleExerciseTimeGoal: UInt,
         appleStandHours: UInt,
         appleStandHoursGoal: UInt) {
        self.date = date
        self.activeEnergyBurned = activeEnergyBurned
        self.activeEnergyBurnedGoal = activeEnergyBurnedGoal
        self.appleExerciseTime = appleExerciseTime
        self.appleExerciseTimeGoal = appleExerciseTimeGoal
        self.appleStandHours = appleStandHours
        self.appleStandHoursGoal = appleStandHoursGoal

        hkActivitySummary = HKActivitySummary(activeEnergyBurned: Double(activeEnergyBurned),
                                              activeEnergyBurnedGoal: Double(activeEnergyBurnedGoal),
                                              exerciseTime: Double(appleExerciseTime),
                                              exerciseTimeGoal: Double(appleExerciseTimeGoal),
                                              standTime: Double(appleStandHours),
                                              standTimeGoal: Double(appleStandHoursGoal))
    }

    public init(date: Date) {
        self.init(date: date,
                  activeEnergyBurned: 0,
                  activeEnergyBurnedGoal: 0,
                  appleExerciseTime: 0,
                  appleExerciseTimeGoal: 0,
                  appleStandHours: 0,
                  appleStandHoursGoal: 0)
    }
}
