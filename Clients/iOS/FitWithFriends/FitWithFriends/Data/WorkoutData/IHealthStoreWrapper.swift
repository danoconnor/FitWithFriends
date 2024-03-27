//
//  IHealthStoreWrapper.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/23/24.
//

import Foundation
import HealthKit

/// Wraps calls to HKHealthStore so that we can mock them as needed for tests
public protocol IHealthStoreWrapper {
    /// Whether the device supports health data
    var isHealthDataAvailable: Bool { get }

    /// Calls HKHealthKit to request permission to access the given types
    func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, 
                              read typesToRead: Set<HKObjectType>?,
                              completion: @escaping (Bool, (any Error)?) -> Void)

    /// Calls HKHealthKit to enable background updates for the given object type
    func enableBackgroundDelivery(for type: HKObjectType, 
                                  frequency: HKUpdateFrequency,
                                  withCompletion completion: @escaping (Bool, (any Error)?) -> Void)

    /// Cteates and executes an HKObserverQuery with the given parameters
    /// See `HKObserverQuery` for details on the parameters
    /// - Returns: The reference to the created HKObserverQuery so the caller can keep it in memory
    func executeObserverQuery(queryDescriptors: [HKQueryDescriptor], 
                              updateHandler: @escaping (HKObserverQuery, Set<HKSampleType>?, @escaping HKObserverQueryCompletionHandler, (any Error)?) -> Void) -> HKObserverQuery

    /// Creates and executes an HKSampleQuery with the given parameters
    /// See `HKSampleQuery` for details on the parameters
    func executeSampleQuery(sampleType: HKSampleType, 
                            predicate: NSPredicate?,
                            limit: Int,
                            sortDescriptors: [NSSortDescriptor]?,
                            resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void)

    /// Creates and executes an HKActivitySummaryQuery with the given parameters
    /// See `HKActivitySummaryQuery` for details on the parameters
    func executeActivitySummaryQuery(predicate: NSPredicate?, 
                                     resultsHandler handler: @escaping (HKActivitySummaryQuery, [HKActivitySummary]?, (any Error)?) -> Void)

    /// Creates and executes an HKStatisticsQuery with the given parameters
    /// See `HKStatisticsQuery` for details on the parameter
    func executeStatisticsQuery(quantityType: HKQuantityType, 
                                quantitySamplePredicate: NSPredicate?,
                                options: HKStatisticsOptions,
                                completionHandler handler: @escaping (HKStatisticsQuery, HKStatistics?, (any Error)?) -> Void)
}
