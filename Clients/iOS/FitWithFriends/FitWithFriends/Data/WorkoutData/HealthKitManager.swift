//
//  HealthKitManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/20.
//

import Combine
import Foundation
import HealthKit

class HealthKitManager {
    private let authenticationManager: AuthenticationManager
    private let userDefaults: UserDefaults

    private static let healthPromptKey = "HasPromptedForHealthPermissions"

    private var loginStateCancellable: AnyCancellable?

    var shouldPromptUser: Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.traceWarning(message: "Health data is not available on this device. Should not prompt user for permissions")
            return false
        }

        // Apple does not provide a way to check the current health permissions,
        // so the best we can do is check if we've shown the prompt before
        return userDefaults.bool(forKey: HealthKitManager.healthPromptKey) != true
    }

    init(authenticationManager: AuthenticationManager,
         userDefaults: UserDefaults) {
        self.authenticationManager = authenticationManager
        self.userDefaults = userDefaults
    }

    func requestHealthKitPermission(completion: @escaping () -> Void) {
        guard shouldPromptUser else {
            Logger.traceInfo(message: "User has already been prompted for health permissions, not prompting again")
            return
        }

        let dataTypes: [HKObjectType] = [
            .workoutType(),
            .activitySummaryType()
        ]

        HKHealthStore().requestAuthorization(toShare: nil, read: Set(dataTypes)) { [weak self] success, error in
            if let error = error {
                Logger.traceError(message: "Failed to request authorization for health data", error: error)
                completion()
                return
            }

            Logger.traceInfo(message: "Request authorization for health data success: \(success)")

            if success {
                self?.userDefaults.set(true, forKey: HealthKitManager.healthPromptKey)
            }

            completion()
        }
    }
}
