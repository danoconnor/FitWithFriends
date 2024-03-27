//
//  HealthStoreWrapper.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/23/24.
//

import Foundation
import HealthKit

public class HealthStoreWrapper: IHealthStoreWrapper {
    private let hkHealthStore: HKHealthStore

    public init() {
        hkHealthStore = HKHealthStore()
    }

    public var isHealthDataAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    public func requestAuthorization(toShare typesToShare: Set<HKSampleType>?,
                              read typesToRead: Set<HKObjectType>?,
                              completion: @escaping (Bool, (any Error)?) -> Void) {
        hkHealthStore.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: completion)
    }

    public func enableBackgroundDelivery(for type: HKObjectType,
                                  frequency: HKUpdateFrequency,
                                  withCompletion completion: @escaping (Bool, (any Error)?) -> Void) {
        hkHealthStore.enableBackgroundDelivery(for: type, frequency: frequency, withCompletion: completion)
    }

    public func executeObserverQuery(queryDescriptors: [HKQueryDescriptor], updateHandler: @escaping (HKObserverQuery, Set<HKSampleType>?, @escaping HKObserverQueryCompletionHandler, (any Error)?) -> Void) -> HKObserverQuery {
        let query = HKObserverQuery(queryDescriptors: queryDescriptors, updateHandler: updateHandler)
        hkHealthStore.execute(query)

        return query
    }

    public func executeSampleQuery(sampleType: HKSampleType,
                            predicate: NSPredicate?,
                            limit: Int,
                            sortDescriptors: [NSSortDescriptor]?,
                            resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void) {
        let query = HKSampleQuery(sampleType: sampleType, 
                                  predicate: predicate,
                                  limit: limit,
                                  sortDescriptors: sortDescriptors,
                                  resultsHandler: resultsHandler)
        hkHealthStore.execute(query)
    }
    
    public func executeActivitySummaryQuery(predicate: NSPredicate?,
                                     resultsHandler handler: @escaping (HKActivitySummaryQuery, [HKActivitySummary]?, (any Error)?) -> Void) {
        let query = HKActivitySummaryQuery(predicate: predicate, resultsHandler: handler)
        hkHealthStore.execute(query)
    }
    
    public func executeStatisticsQuery(quantityType: HKQuantityType,
                                quantitySamplePredicate: NSPredicate?,
                                options: HKStatisticsOptions,
                                completionHandler handler: @escaping (HKStatisticsQuery, HKStatistics?, (any Error)?) -> Void) {
        let query = HKStatisticsQuery(quantityType: quantityType,
                                      quantitySamplePredicate: quantitySamplePredicate,
                                      options: options,
                                      completionHandler: handler)
        hkHealthStore.execute(query)
    }
}
