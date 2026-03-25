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

    public var requestHealthKitPermissionCallCount = 0
    public func requestHealthKitPermission(completion: @escaping () -> Void) {
        requestHealthKitPermissionCallCount += 1
        // Call completion from a new thread to better mock the real HealthKitManager behavior
        DispatchQueue.global().async {
            completion()
        }
    }

    public var return_getCurrentActivitySummary: ActivitySummary?
    public var getCurrentActivitySummaryCallCount = 0
    public func getCurrentActivitySummary(completion: @escaping (ActivitySummary?) -> Void) {
        getCurrentActivitySummaryCallCount += 1
        DispatchQueue.global().async {
            completion(self.return_getCurrentActivitySummary)
        }
    }

    public var setupObserverQueriesCallCount = 0
    public func setupObserverQueries() {
        setupObserverQueriesCallCount += 1
    }
}
