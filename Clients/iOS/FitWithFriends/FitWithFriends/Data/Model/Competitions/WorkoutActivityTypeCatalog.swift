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
    public enum Category: String, CaseIterable, Identifiable {
        case cardio
        case strength
        case outdoor
        case mindBody

        public var id: String { rawValue }

        public var displayName: String {
            switch self {
            case .cardio: return "Cardio"
            case .strength: return "Strength"
            case .outdoor: return "Outdoor"
            case .mindBody: return "Mind & Body"
            }
        }
    }

    public struct Entry: Hashable, Identifiable {
        public let rawValue: UInt
        public let displayName: String
        public let category: Category
        public var id: UInt { rawValue }
    }

    /// Small curated list covering the common cases. Users needing an activity not listed here
    /// can leave the filter empty (counts all workouts).
    public static let commonEntries: [Entry] = [
        Entry(rawValue: UInt(HKWorkoutActivityType.running.rawValue),                       displayName: "Running",            category: .cardio),
        Entry(rawValue: UInt(HKWorkoutActivityType.walking.rawValue),                       displayName: "Walking",            category: .cardio),
        Entry(rawValue: UInt(HKWorkoutActivityType.cycling.rawValue),                       displayName: "Cycling",            category: .cardio),
        Entry(rawValue: UInt(HKWorkoutActivityType.swimming.rawValue),                      displayName: "Swimming",           category: .cardio),
        Entry(rawValue: UInt(HKWorkoutActivityType.rowing.rawValue),                        displayName: "Rowing",             category: .cardio),
        Entry(rawValue: UInt(HKWorkoutActivityType.elliptical.rawValue),                    displayName: "Elliptical",         category: .cardio),
        Entry(rawValue: UInt(HKWorkoutActivityType.stairClimbing.rawValue),                 displayName: "Stair Climbing",     category: .cardio),
        Entry(rawValue: UInt(HKWorkoutActivityType.highIntensityIntervalTraining.rawValue), displayName: "HIIT",               category: .cardio),

        Entry(rawValue: UInt(HKWorkoutActivityType.traditionalStrengthTraining.rawValue),   displayName: "Strength",           category: .strength),
        Entry(rawValue: UInt(HKWorkoutActivityType.functionalStrengthTraining.rawValue),    displayName: "Functional Strength", category: .strength),
        Entry(rawValue: UInt(HKWorkoutActivityType.coreTraining.rawValue),                  displayName: "Core Training",      category: .strength),

        Entry(rawValue: UInt(HKWorkoutActivityType.hiking.rawValue),                        displayName: "Hiking",             category: .outdoor),

        Entry(rawValue: UInt(HKWorkoutActivityType.yoga.rawValue),                          displayName: "Yoga",               category: .mindBody),
        Entry(rawValue: UInt(HKWorkoutActivityType.socialDance.rawValue),                   displayName: "Dance",              category: .mindBody),
        Entry(rawValue: UInt(HKWorkoutActivityType.martialArts.rawValue),                   displayName: "Martial Arts",       category: .mindBody),
    ]

    public static func entries(in category: Category) -> [Entry] {
        commonEntries.filter { $0.category == category }
    }

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
        return "Workout \(rawValue)"
    }
}
