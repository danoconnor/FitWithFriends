//
//  MockHealthKitManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

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
}
