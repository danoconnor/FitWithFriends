//
//  MockHealthKitManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation
import HealthKit

class MockHealthKitManager: HealthKitManager {
    var return_shouldPromptUser = false
    override var shouldPromptUser: Bool {
        return return_shouldPromptUser
    }

    init() {
        super.init(activityDataService: MockActivityDataService(),
                   activityUpdateDelegate: MockCompetitionManager(),
                   authenticationManager: MockAuthenticationManager(),
                   userDefaults: UserDefaults.standard)

        // Default to returning some activity data
        let activitySummary = HKActivitySummary()
        activitySummary.activeEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: 351.027)
        activitySummary.appleExerciseTime = HKQuantity(unit: .minute(), doubleValue: 12.3)
        activitySummary.appleStandHours = HKQuantity(unit: .count(), doubleValue: 4)
        activitySummary.appleStandHoursGoal = HKQuantity(unit: .count(), doubleValue: 12)
        activitySummary.appleExerciseTimeGoal = HKQuantity(unit: .minute(), doubleValue: 30)
        activitySummary.activeEnergyBurnedGoal = HKQuantity(unit: .kilocalorie(), doubleValue: 700)

        return_currentActivitySummary = activitySummary
    }

    override func requestHealthKitPermission(completion: @escaping () -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            completion()
        }
    }

    override func setupQueries() {}

    var return_currentActivitySummary: HKActivitySummary?
    override func getCurrentActivitySummary(completion: @escaping (HKActivitySummary?) -> Void) {
        completion(return_currentActivitySummary)
    }
}
