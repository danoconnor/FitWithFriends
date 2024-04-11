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

    public func executeWorkoutSampleQuery(predicate: NSPredicate?,
                                          limit: Int,
                                          sortDescriptors: [NSSortDescriptor]?,
                                          resultsHandler: @escaping (HKSampleQuery, [WorkoutSampleDTO]?, (any Error)?) -> Void) {
        let query = HKSampleQuery(sampleType: .workoutType(),
                                  predicate: predicate,
                                  limit: limit,
                                  sortDescriptors: sortDescriptors) { query, samples, error in
            let dto = samples?.compactMap { sample in
                if let workoutSample = sample as? HKWorkout {
                    return WorkoutSampleDTO(workout: workoutSample)
                } else {
                    Logger.traceWarning(message: "Sample was not of type HKWorkout. Actual type: \(type(of: sample))")
                    return nil
                }
            }

            resultsHandler(query, dto, error)
        }
        hkHealthStore.execute(query)
    }
    
    public func executeActivitySummaryQuery(predicate: NSPredicate?,
                                     resultsHandler handler: @escaping (HKActivitySummaryQuery, [ActivitySummaryDTO]?, (any Error)?) -> Void) {
        let query = HKActivitySummaryQuery(predicate: predicate) { query, summaries, error in
            let dto = summaries?.compactMap { ActivitySummaryDTO(hkActivitySummary: $0) }
            handler(query, dto, error)
        }
        hkHealthStore.execute(query)
    }
    
    public func executeStatisticsQuery(quantityType: HKQuantityType,
                                       resultUnit: HKUnit,
                                       quantitySamplePredicate: NSPredicate?,
                                       options: HKStatisticsOptions,
                                       completionHandler handler: @escaping (HKStatisticsQuery, StatisticDTO?, (any Error)?) -> Void) {
        let query = HKStatisticsQuery(quantityType: quantityType,
                                      quantitySamplePredicate: quantitySamplePredicate,
                                      options: options) { query, statistic, error in
            let dto: StatisticDTO?
            if let statistic = statistic {
                dto = StatisticDTO(hkStatistic: statistic, unit: resultUnit)
            } else {
                // The error field should be populated in this case
                dto = nil
            }

            handler(query, dto, error)
        }
        hkHealthStore.execute(query)
    }
}
