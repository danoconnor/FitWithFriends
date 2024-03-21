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
    let activityTypeRawValue: UInt
    let distance: Double?

    var activityType: HKWorkoutActivityType {
        return HKWorkoutActivityType(rawValue: activityTypeRawValue) ?? .other
    }

    init(workout: HKWorkout) {
        startDate = workout.startDate
        caloriesBurned = round(workout.totalEnergyBurned?.doubleValue(for: .largeCalorie()) ?? 0)
        duration = round(workout.duration)
        activityTypeRawValue = workout.workoutActivityType.rawValue

        switch workout.workoutActivityType {
        case .crossCountrySkiing,
             .cycling,
             .elliptical,
             .hiking,
             .paddleSports,
             .rowing,
             .running,
             .swimming,
             .walking,
             .swimBikeRun:
            distance = round(workout.totalDistance?.doubleValue(for: .mile()) ?? 0)
        case .stairs,
             .stairClimbing:
            // For stair workouts, we measure distance in terms of stairs climbed instead of distance
            distance = round(workout.totalFlightsClimbed?.doubleValue(for: .count()) ?? 0)
        default:
            distance = nil
        }
    }
}
