//
//  DailySummary.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/9/26.
//

import Foundation

public class DailySummary: IdentifiableBase, Codable {
    enum CodingKeys: String, CodingKey {
        case date
        case caloriesBurned
        case caloriesGoal
        case exerciseTime
        case exerciseTimeGoal
        case standTime
        case standTimeGoal
        case points
    }

    let date: Date
    let caloriesBurned: UInt
    let caloriesGoal: UInt
    let exerciseTime: UInt
    let exerciseTimeGoal: UInt
    let standTime: UInt
    let standTimeGoal: UInt
    let points: Double

    init(date: Date = Date(),
         caloriesBurned: UInt = 0, caloriesGoal: UInt = 400,
         exerciseTime: UInt = 0, exerciseTimeGoal: UInt = 30,
         standTime: UInt = 0, standTimeGoal: UInt = 12,
         points: Double = 0) {
        self.date = date
        self.caloriesBurned = caloriesBurned
        self.caloriesGoal = caloriesGoal
        self.exerciseTime = exerciseTime
        self.exerciseTimeGoal = exerciseTimeGoal
        self.standTime = standTime
        self.standTimeGoal = standTimeGoal
        self.points = points
    }
}
