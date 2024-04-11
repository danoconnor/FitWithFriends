//
//  WorkoutSampleDTO.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/6/24.
//

import Foundation
import HealthKit

public struct WorkoutSampleDTO {
    public let startDate: Date
    public let duration: TimeInterval
    public let caloriesBurned: Double
    public let activityType: HKWorkoutActivityType
    public let distance: Double?
    public let unit: Unit

    public init(workout: HKWorkout) {
        startDate = workout.startDate
        caloriesBurned = round(workout.totalEnergyBurned?.doubleValue(for: .largeCalorie()) ?? 0)
        duration = round(workout.duration)
        activityType = workout.workoutActivityType

        switch activityType {
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
            unit = .mile
        case .stairs,
             .stairClimbing:
            // For stair workouts, we measure distance in terms of stairs climbed instead of distance
            distance = round(workout.totalFlightsClimbed?.doubleValue(for: .count()) ?? 0)
            unit = .count
        default:
            distance = nil
            unit = .none
        }
    }

    /// Initializer for unit tests, not used in production code
    public init(startDate: Date, 
                duration: TimeInterval,
                caloriesBurned: Double,
                activityType: HKWorkoutActivityType,
                distance: Double?,
                unit: Unit) {
        self.startDate = startDate
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.activityType = activityType
        self.distance = distance
        self.unit = unit
    }
}
