//
//  MockHealthStoreWrapper.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/24/24.
//

import Foundation
import HealthKit

public class MockHealthStoreWrapper: IHealthStoreWrapper {
    public init() {}

    public var isHealthDataAvailable: Bool = true

    public var param_typesToShare: Set<HKSampleType>?
    public var param_typesToRead: Set<HKObjectType>?
    public var return_authorizationSuccess: Bool = true
    public var return_authorizationError: Error?
    public func requestAuthorization(toShare typesToShare: Set<HKSampleType>?,
                              read typesToRead: Set<HKObjectType>?, 
                              completion: @escaping (Bool, (any Error)?) -> Void) {
        param_typesToShare = typesToShare
        param_typesToRead = typesToRead

        // Kick it to a background thread to better mock the real HealthStoreWrapper
        DispatchQueue.global().async {
            completion(self.return_authorizationSuccess, self.return_authorizationError)
        }
    }

    public var requestedBackgroundTypes: [(type: HKObjectType, frequency: HKUpdateFrequency)] = []
    public var param_backgroundDelivery_type: HKObjectType?
    public var param_backgroundDelivery_frequency: HKUpdateFrequency?
    public var return_enableBackgroundDeliverySuccess: Bool = true
    public var return_enableBackgroundDeliveryError: Error?
    public func enableBackgroundDelivery(for type: HKObjectType, frequency: HKUpdateFrequency, withCompletion completion: @escaping (Bool, (any Error)?) -> Void) {
        param_backgroundDelivery_type = type
        param_backgroundDelivery_frequency = frequency

        requestedBackgroundTypes.append((type: type, frequency: frequency))

        // Kick it to a background thread to better mock the real HealthStoreWrapper
        DispatchQueue.global().async {
            completion(self.return_enableBackgroundDeliverySuccess, self.return_enableBackgroundDeliveryError)
        }
    }
    
    public var param_queryDescriptors: [HKQueryDescriptor]?
    public var param_updateHandler: ((HKObserverQuery, Set<HKSampleType>?, @escaping HKObserverQueryCompletionHandler, (any Error)?) -> Void)?
    public var return_observerQuery: HKObserverQuery?
    public func executeObserverQuery(queryDescriptors: [HKQueryDescriptor], updateHandler: @escaping (HKObserverQuery, Set<HKSampleType>?, @escaping HKObserverQueryCompletionHandler, (any Error)?) -> Void) -> HKObserverQuery {
        param_queryDescriptors = queryDescriptors
        param_updateHandler = updateHandler

        return_observerQuery = HKObserverQuery(queryDescriptors: queryDescriptors,
                                               updateHandler: updateHandler)
        return return_observerQuery!
    }
    

    public var param_sampleQuery_predicate: NSPredicate?
    public var param_sampleQuery_limit: Int?
    public var param_sampleQuery_sortDescriptors: [NSSortDescriptor]?
    public var param_sampleQuery_resultsHandler: ((HKSampleQuery, [WorkoutSampleDTO]?, (any Error)?) -> Void)?
    public var return_sampleQuery_samples: [WorkoutSampleDTO]?
    public var return_sampleQuery_error: Error?
    public func executeWorkoutSampleQuery(predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?, resultsHandler: @escaping (HKSampleQuery, [WorkoutSampleDTO]?, (any Error)?) -> Void) {
        param_sampleQuery_predicate = predicate
        param_sampleQuery_limit = limit
        param_sampleQuery_sortDescriptors = sortDescriptors
        param_sampleQuery_resultsHandler = resultsHandler

        // Create the query because we need to return it, but we aren't going to actually execute this query
        let sampleQuery = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: limit, sortDescriptors: sortDescriptors) { _, _, _ in
            // No need to call the handler here, we will call it manually because we aren't actually executing this query
        }

        // Kick it to a background thread to better mock the real HealthStoreWrapper
        DispatchQueue.global().async {
            resultsHandler(sampleQuery, self.return_sampleQuery_samples, self.return_sampleQuery_error)
        }
    }
    
    public var param_activitySummaryQuery_predicate: NSPredicate?
    public var param_activitySummaryQuery_handler: ((HKActivitySummaryQuery, [ActivitySummaryDTO]?, (any Error)?) -> Void)?
    public var return_activitySummaryQuery_activitySummaries: [ActivitySummaryDTO]?
    public var return_activitySummaryQuery_error: Error?
    public func executeActivitySummaryQuery(predicate: NSPredicate?, resultsHandler handler: @escaping (HKActivitySummaryQuery, [ActivitySummaryDTO]?, (any Error)?) -> Void) {
        param_activitySummaryQuery_predicate = predicate
        param_activitySummaryQuery_handler = handler

        // Create the query because we need to return it, but we aren't going to actually execute this query
        let activitySummaryQuery = HKActivitySummaryQuery(predicate: predicate) { _, _, _ in
            // No need to call the handler here, we will call it manually because we aren't actually executing this query
        }

        // Kick it to a background thread to better mock the real HealthStoreWrapper
        DispatchQueue.global().async {
            handler(activitySummaryQuery, self.return_activitySummaryQuery_activitySummaries, self.return_activitySummaryQuery_error)
        }
    }
    
    public var param_statisticsQuery_quantityType: HKQuantityType?
    public var param_statisticsQuery_resultUnit: HKUnit?
    public var param_statisticsQuery_quantitySamplePredicate: NSPredicate?
    public var param_statisticsQuery_options: HKStatisticsOptions?
    public var param_statisticsQuery_handler: ((HKStatisticsQuery, StatisticDTO?, (any Error)?) -> Void)?
    public var return_statisticsQuery_statistics: [HKQuantityType: StatisticDTO] = [:]
    public var return_statisticsQuery_error: Error?
    public func executeStatisticsQuery(quantityType: HKQuantityType, resultUnit: HKUnit, quantitySamplePredicate: NSPredicate?, options: HKStatisticsOptions, completionHandler handler: @escaping (HKStatisticsQuery, StatisticDTO?, (any Error)?) -> Void) {
        param_statisticsQuery_quantityType = quantityType
        param_statisticsQuery_resultUnit = resultUnit
        param_statisticsQuery_quantitySamplePredicate = quantitySamplePredicate
        param_statisticsQuery_options = options
        param_statisticsQuery_handler = handler

        // Create the query because we need to return it, but we aren't going to actually execute this query
        let statisticsQuery = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: quantitySamplePredicate, options: options) { _, _, _ in
            // No need to call the handler here, we will call it manually because we aren't actually executing this query
        }

        // Kick it to a background thread to better mock the real HealthStoreWrapper
        DispatchQueue.global().async {
            let statisticsToReturn = self.return_statisticsQuery_statistics[quantityType]
            handler(statisticsQuery, statisticsToReturn, self.return_statisticsQuery_error)
        }
    }
    
    // MARK: Helper public functions

    /// Call this public function to trigger the observer callback that was setup in executeObserverQuery
    public func triggerObserverQueryUpdate(updatedTypes: Set<HKSampleType>?, completion: @escaping HKObserverQueryCompletionHandler) {
        param_updateHandler?(return_observerQuery!, updatedTypes, completion, nil)
    }
}
