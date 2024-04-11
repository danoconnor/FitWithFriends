//
//  Workout.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/29/20.
//

import Foundation
import HealthKit

public class Workout: Codable {
    public let startDate: Date
    public let duration: TimeInterval
    public let caloriesBurned: Double
    public let activityTypeRawValue: UInt
    public let distance: Double?
    public let unit: Unit

    public var activityType: HKWorkoutActivityType {
        return HKWorkoutActivityType(rawValue: activityTypeRawValue) ?? .other
    }

    public init(workout: WorkoutSampleDTO) {
        startDate = workout.startDate
        duration = workout.duration
        caloriesBurned = workout.caloriesBurned
        activityTypeRawValue = workout.activityType.rawValue
        distance = workout.distance
        unit = workout.unit
    }
}
