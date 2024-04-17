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
    public let duration: UInt
    public let caloriesBurned: UInt
    public let appleActivityTypeRawValue: UInt
    public let distance: UInt?
    public let unit: Unit

    public var activityType: HKWorkoutActivityType {
        return HKWorkoutActivityType(rawValue: appleActivityTypeRawValue) ?? .other
    }

    public init(workout: WorkoutSampleDTO) {
        startDate = workout.startDate
        duration = UInt(round(workout.duration))
        caloriesBurned = UInt(round(workout.caloriesBurned))
        appleActivityTypeRawValue = workout.activityType.rawValue
        distance = workout.distance != nil ? UInt(round(workout.distance!)) : nil
        unit = workout.unit
    }
}
