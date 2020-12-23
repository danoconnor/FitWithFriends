//
//  Workout.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/29/20.
//

import Foundation
import HealthKit

class Workout: Codable {
    let startDate: Date
    let duration: TimeInterval
    let caloriesBurned: Double

    init(workout: HKWorkout) {
        startDate = workout.startDate
        caloriesBurned = workout.totalEnergyBurned?.doubleValue(for: .largeCalorie()) ?? 0
        duration = workout.duration
    }
}
