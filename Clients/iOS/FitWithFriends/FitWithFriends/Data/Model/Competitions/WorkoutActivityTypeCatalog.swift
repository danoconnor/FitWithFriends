//
//  WorkoutActivityTypeCatalog.swift
//  FitWithFriends
//
//  Curated list of HKWorkoutActivityType values presented to users when configuring
//  a "Tracked Workouts" scoring rule. Values match HealthKit raw ints.
//

import Foundation
import HealthKit

public enum WorkoutActivityTypeCatalog {
    public struct Entry: Hashable, Identifiable {
        public let rawValue: UInt
        public let displayName: String
        public var id: UInt { rawValue }
    }

    /// Small curated list covering the common cases. Users needing an activity not listed here
    /// can leave the filter empty (counts all workouts).
    public static let commonEntries: [Entry] = [
        Entry(rawValue: UInt(HKWorkoutActivityType.running.rawValue), displayName: "Running"),
        Entry(rawValue: UInt(HKWorkoutActivityType.walking.rawValue), displayName: "Walking"),
        Entry(rawValue: UInt(HKWorkoutActivityType.cycling.rawValue), displayName: "Cycling"),
        Entry(rawValue: UInt(HKWorkoutActivityType.swimming.rawValue), displayName: "Swimming"),
        Entry(rawValue: UInt(HKWorkoutActivityType.hiking.rawValue), displayName: "Hiking"),
        Entry(rawValue: UInt(HKWorkoutActivityType.rowing.rawValue), displayName: "Rowing"),
        Entry(rawValue: UInt(HKWorkoutActivityType.elliptical.rawValue), displayName: "Elliptical"),
        Entry(rawValue: UInt(HKWorkoutActivityType.yoga.rawValue), displayName: "Yoga"),
        Entry(rawValue: UInt(HKWorkoutActivityType.highIntensityIntervalTraining.rawValue), displayName: "HIIT"),
        Entry(rawValue: UInt(HKWorkoutActivityType.traditionalStrengthTraining.rawValue), displayName: "Strength"),
        Entry(rawValue: UInt(HKWorkoutActivityType.functionalStrengthTraining.rawValue), displayName: "Functional Strength"),
        Entry(rawValue: UInt(HKWorkoutActivityType.coreTraining.rawValue), displayName: "Core Training"),
        Entry(rawValue: UInt(HKWorkoutActivityType.socialDance.rawValue), displayName: "Dance"),
        Entry(rawValue: UInt(HKWorkoutActivityType.martialArts.rawValue), displayName: "Martial Arts"),
        Entry(rawValue: UInt(HKWorkoutActivityType.stairClimbing.rawValue), displayName: "Stair Climbing"),
    ]

    public static func displayName(for rawValue: UInt) -> String? {
        if let match = commonEntries.first(where: { $0.rawValue == rawValue }) {
            return match.displayName
        }
        if let type = HKWorkoutActivityType(rawValue: rawValue) {
            return type.fallbackDisplayName
        }
        return nil
    }
}

private extension HKWorkoutActivityType {
    var fallbackDisplayName: String {
        // Generic fallback when the type isn't in the curated list.
        return "Workout \(rawValue)"
    }
}
