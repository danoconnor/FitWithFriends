//
//  MockHealthKitManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation
import HealthKit

public class MockHealthKitManager: IHealthKitManager {
    public var shouldPromptUser: Bool = false

    public func requestHealthKitPermission(completion: @escaping () -> Void) {
        // Call completion from a new thread to better mock the real HealthKitManager behavior
        DispatchQueue.global().async {
            completion()
        }
    }

    public var return_getCurrentActivitySummary: ActivitySummary?
    public func getCurrentActivitySummary(completion: @escaping (ActivitySummary?) -> Void) {
        DispatchQueue.global().async {
            completion(self.return_getCurrentActivitySummary)
        }
    }

    public func setupObserverQueries() {}
}
