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
        super.init(activityDataService: MockActivityDataService(), authenticationManager: MockAuthenticationManager(), userDefaults: UserDefaults.standard)
    }

    override func requestHealthKitPermission(completion: @escaping () -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            completion()
        }
    }

    override func registerDataQueries() {}

    override func registerForBackgroundUpdates() {}

    var return_currentActivitySummary: HKActivitySummary?
    override func getCurrentActivitySummary(completion: @escaping (HKActivitySummary?) -> Void) {
        completion(return_currentActivitySummary)

        //        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
//            completion(self?.return_currentActivitySummary)
//        }
    }
}
