//
//  IHealthKitManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/24/24.
//

import Foundation

public protocol IHealthKitManager {
    /// Whether we should prompt the user for health data access or not
    var shouldPromptUser: Bool { get }

    /// Request user permission to access the HealthKit data that we need
    func requestHealthKitPermission(completion: @escaping () -> Void)

    /// Get the activity summary for the current day
    /// If we have health data access but don't have any available data, then this will return an empty ActivitySummary
    /// If we do not have health data access, then this will return nil
    func getCurrentActivitySummary(completion: @escaping (ActivitySummary?) -> Void)

    /// Setup the queries that receive updates when there is new data available
    func setupObserverQueries()
}
