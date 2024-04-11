//
//  HealthKitManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/20.
//

import Combine
import Foundation
import HealthKit
import UIKit

public class HealthKitManager: IHealthKitManager {
    public enum HealthKitError: LocalizedError, CustomStringConvertible {
        case unknownQuantityType(type: HKQuantityTypeIdentifier)

        public var description: String {
            switch self {
            case let .unknownQuantityType(type):
                return "Unknown quantity type in statistics query. Type: \(type.rawValue)"
            }
        }
    }

    private let activityDataService: IActivityDataService
    private let activityUpdateDelegate: ActivityUpdateDelegate
    private let authenticationManager: AuthenticationManager
    private let healthStoreWrapper: IHealthStoreWrapper
    private let userDefaults: UserDefaults

    private let activitySummaryQueue = DispatchQueue(label: "ActivitySummaryQueue")

    // User defaults keys
    public static let healthPromptKey = "HasPromptedForHealthPermissions"
    public static let lastKnownCalorieGoalKey = "LastKnownCalorieGoal"
    public static let lastKnownExerciseGoalKey = "LastKnownExerciseGoal"
    public static let lastKnownStandGoalKey = "LastKnownStandGoal"
    public static let lastActivityDataUpdateKey = "LastActivityDataUpdate"
    public static let lastWorkoutUpdateKey = "LastWorkoutUpdate"

    private static let backgroundTaskTimeout: TimeInterval = 60 // 60 seconds

    /// The various data points that we want to observe and report to our backend for score calculation
    /// We will observe these, plus activity summaries and workouts
    private static let quantityTypesToObserve: [HKQuantityTypeIdentifier] = [
        .activeEnergyBurned,
        .appleExerciseTime,
        .appleStandTime,
        .stepCount,
        .distanceWalkingRunning,
        .flightsClimbed
    ]

    /// Hold onto a reference to our query so it doesn't get deinitialized
    private var observerQuery: HKQuery?

    private var loginStateCancellable: AnyCancellable?

    private var lastKnownCalorieGoal: Double {
        userDefaults.double(forKey: HealthKitManager.lastKnownCalorieGoalKey)
    }

    private var lastKnownExerciseGoal: Double {
        userDefaults.double(forKey: HealthKitManager.lastKnownExerciseGoalKey)
    }

    private var lastKnownStandGoal: Double {
        userDefaults.double(forKey: HealthKitManager.lastKnownStandGoalKey)
    }

    public var shouldPromptUser: Bool {
        guard healthStoreWrapper.isHealthDataAvailable else {
            Logger.traceWarning(message: "Health data is not available on this device. Should not prompt user for permissions")
            return false
        }

        // Apple does not provide a way to check the current health permissions,
        // so the best we can do is check if we've shown the prompt before
        return userDefaults.bool(forKey: HealthKitManager.healthPromptKey) != true
    }

    public init(activityDataService: IActivityDataService,
         activityUpdateDelegate: ActivityUpdateDelegate,
         authenticationManager: AuthenticationManager,
         healthStoreWrapper: IHealthStoreWrapper,
         userDefaults: UserDefaults) {
        self.activityDataService = activityDataService
        self.activityUpdateDelegate = activityUpdateDelegate
        self.authenticationManager = authenticationManager
        self.healthStoreWrapper = healthStoreWrapper
        self.userDefaults = userDefaults

        loginStateCancellable = authenticationManager.$loginState.sink { [weak self] state in
            switch state {
            case .loggedIn:
                // Report the activity summaries when the user logs in
                self?.activitySummaryQueue.async {
                    Logger.traceInfo(message: "Starting report data due to login")
                    let dispatchGroup = DispatchGroup()

                    dispatchGroup.enter()
                    self?.reportWorkouts() {
                        Logger.traceVerbose(message: "Report workouts after login complete")
                        dispatchGroup.leave()
                    }

                    dispatchGroup.enter()
                    self?.reportActivitySummaries() {
                        Logger.traceVerbose(message: "Report activity summaries after login complete")
                        dispatchGroup.leave()
                    }

                    let waitResult = dispatchGroup.wait(timeout: .now() + HealthKitManager.backgroundTaskTimeout)
                    if waitResult == .success {
                        Logger.traceInfo(message: "Completed report data after login")
                    } else {
                        Logger.traceError(message: "Report data after login timed out")
                    }
                }
            default:
                break
            }
        }
    }

    public func requestHealthKitPermission(completion: @escaping () -> Void) {
        guard shouldPromptUser else {
            Logger.traceInfo(message: "User has already been prompted for health permissions, not prompting again")
            completion()
            return
        }

        var dataTypes: [HKObjectType] = [
            .workoutType(),
            .activitySummaryType()
        ]
        dataTypes.append(contentsOf: HealthKitManager.quantityTypesToObserve.map { HKQuantityType($0) })

        healthStoreWrapper.requestAuthorization(toShare: nil, read: Set(dataTypes)) { [weak self] success, error in
            if let error = error {
                Logger.traceError(message: "Failed to request authorization for health data", error: error)
                completion()
                return
            }

            Logger.traceInfo(message: "Request authorization for health data success: \(success)")

            if success {
                self?.userDefaults.set(true, forKey: HealthKitManager.healthPromptKey)
                self?.setupObserverQueries()
            }

            completion()
        }
    }

    public func setupObserverQueries() {
        registerObserverQueries()
        registerForBackgroundUpdates()
    }

    public func getCurrentActivitySummary(completion: @escaping (ActivitySummary?) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        var today = calendar.dateComponents([.day, .month, .year, .era], from: now)
        today.calendar = calendar

        Logger.traceVerbose(message: "Begin get activity summary for \(today)")

        guard healthStoreWrapper.isHealthDataAvailable else {
            Logger.traceWarning(message: "Health data is not available on this device, can't query current activity summary")
            completion(nil)
            return
        }

        let dispatchGroup = DispatchGroup()
        var resultActivitySummaryDTO: ActivitySummaryDTO?
        var resultQuantities: [HKQuantityTypeIdentifier: StatisticDTO] = [:]
        let quantityQueue = DispatchQueue(label: "CurrentActivitySummary_QuantityQueue")

        // Get the HKActivitySummary for today
        let activitySummaryPredicate = HKQuery.predicateForActivitySummary(with: today)
        dispatchGroup.enter()
        healthStoreWrapper.executeActivitySummaryQuery(predicate: activitySummaryPredicate) { _, summaries, error in
            defer {
                dispatchGroup.leave()
            }

            if let error = error {
                Logger.traceError(message: "Failed to get activity summary for \(now)", error: error)
                return
            }

            let summary = summaries?.first { calendar.dateComponents([.day, .month, .year, .era], from: $0.date) == today }

            // Update our last known goals if we were able to successfully get the summary
            // These are used when there is no data for the current day so we can show the empty rings on the homepage
            if let summary = summary {
                self.userDefaults.set(summary.activeEnergyBurnedGoal, forKey: HealthKitManager.lastKnownCalorieGoalKey)
                self.userDefaults.set(summary.appleExerciseTimeGoal, forKey: HealthKitManager.lastKnownExerciseGoalKey)
                self.userDefaults.set(summary.appleStandHoursGoal, forKey: HealthKitManager.lastKnownStandGoalKey)

                Logger.traceVerbose(message: "Successfully got activity summary for \(today)")
                resultActivitySummaryDTO = summary
            } else {
                Logger.traceWarning(message: "Could not find activity summary for \(today) in result")
            }
        }

        // Get all the various statistics that we care about for today (step count, stairs climbed, etc.)
        for quantityType in HealthKitManager.quantityTypesToObserve {
            dispatchGroup.enter()
            getQuantityForDay(quantityTypeId: quantityType, date: now) { error, result in
                defer {
                    dispatchGroup.leave()
                }

                guard let result = result else {
                    Logger.traceError(message: "Failed to get quantity \(String(describing: quantityType)) for \(now)")
                    return
                }

                quantityQueue.sync {
                    resultQuantities[quantityType] = result
                }

                Logger.traceVerbose(message: "Successfully got quantity \(String(describing: quantityType)) for \(now)")
            }
        }

        // Once we have all the data, merge it into one ActivitySummary and return
        dispatchGroup.notify(queue: .global()) {
            Logger.traceVerbose(message: "Completed data queries for activity summary for \(today)")

            let resultActivitySummaryDTO = resultActivitySummaryDTO ?? ActivitySummaryDTO(date: now)
            let activitySummary = ActivitySummary(activitySummary: resultActivitySummaryDTO)

            for quantity in resultQuantities {
                activitySummary.updateStatistic(quantityType: quantity.key, value: quantity.value)
            }

            completion(activitySummary)
        }
    }

    /// Register for hourly background updates for calorie, exercise, stand, steps, distance, and flights climbed
    private func registerForBackgroundUpdates() {
        guard healthStoreWrapper.isHealthDataAvailable else {
            Logger.traceWarning(message: "Health data is not available on this device, not registering for background updates")
            return
        }

        for quantityType in HealthKitManager.quantityTypesToObserve {
            healthStoreWrapper.enableBackgroundDelivery(for: HKQuantityType(quantityType),
                                                        frequency: .hourly) { success, error in
                if let error = error {
                    Logger.traceError(message: "Failed to enable background delivery for \(quantityType)", error: error)
                } else {
                    Logger.traceInfo(message: "Enabled background delivery for \(quantityType): \(success)")
                }
            }
        }

        // Register for background updates when a workout completes
        healthStoreWrapper.enableBackgroundDelivery(for: .workoutType(),
                                                    frequency: .immediate) { success, error in
            if let error = error {
                Logger.traceError(message: "Failed to enable background delivery for workout type", error: error)
            } else {
                Logger.traceInfo(message: "Enabled background delivery for workout type: \(success)")
            }
        }
    }

    /// Sets up a query that will execute when the calorie, exercise, or stand data is updated
    /// It will only execute max once an hour and only if the device is unlocked
    private func registerObserverQueries() {
        guard healthStoreWrapper.isHealthDataAvailable else {
            Logger.traceWarning(message: "Health data is not available on this device, not registering data queries")
            return
        }

        var queryDescriptors = [
            HKQueryDescriptor(sampleType: HKObjectType.workoutType(), predicate: nil),
        ]
        queryDescriptors.append(contentsOf: HealthKitManager.quantityTypesToObserve.map {
            HKQueryDescriptor(sampleType: HKQuantityType($0), predicate: nil)
        })

        let query = healthStoreWrapper.executeObserverQuery(queryDescriptors: queryDescriptors,
                                                            updateHandler: observerQueryUpdateHandler(query:samples:completion:error:))

        // Hold a reference to the query so it continues to be updated while the app is in memory
        observerQuery = query
    }

    /// This function will be called when iOS wakes our app up in the background to report updates
    /// iOS will only tell us that data has changed (via the samples param) but we need to go query for that data separately
    /// This func will query the daily activity summaries that happened since the last update and report them to the service
    private func observerQueryUpdateHandler(query: HKObserverQuery,
                                            samples: Set<HKSampleType>?,
                                            completion: @escaping HKObserverQueryCompletionHandler,
                                            error: Error?) {
        if let error = error {
            Logger.traceError(message: "Error in observer query", error: error)
            completion()
            return
        }

        Logger.traceInfo(message: "Received observer query update for samples \(samples?.map { String(describing: $0) }.joined(separator: ",") ?? "nil")")
        guard let samples = samples,
            samples.count > 0 else {
            Logger.traceWarning(message: "Received empty update from observer")
            return
        }

        activitySummaryQueue.async { [weak self] in
            let dispatchGroup = DispatchGroup()

            if samples.contains(HKSampleType.workoutType()) {
                dispatchGroup.enter()
                self?.reportWorkouts() {
                    Logger.traceVerbose(message: "Workout upload complete")
                    dispatchGroup.leave()
                }
            }

            // Any quantity types that we observe will be included in our activity summary reports
            if samples.intersection(HealthKitManager.quantityTypesToObserve.map { HKQuantityType($0) }).count > 0 {
                dispatchGroup.enter()
                self?.reportActivitySummaries() {
                    Logger.traceVerbose(message: "Activity summary upload complete")
                    dispatchGroup.leave()
                }
            }

            let waitResult = dispatchGroup.wait(timeout: .now() + HealthKitManager.backgroundTaskTimeout)
            if waitResult == .timedOut {
                Logger.traceError(message: "Report data timed out")
                completion()
                return
            }

            Logger.traceVerbose(message: "Report data complete")
            completion()
        }
    }

    private func reportWorkouts(completion: @escaping () -> Void) {
        // Query for the workouts that have been added since the last update
        let dateRange = getQueryDateRange(for: HealthKitManager.lastWorkoutUpdateKey)
        let workoutActivityPredicate = HKQuery.predicateForWorkoutActivities(start: dateRange.startCompenents.date,
                                                                             end: dateRange.endComponents.date)
        let workoutPredicate = HKQuery.predicateForWorkouts(activityPredicate: workoutActivityPredicate)

        healthStoreWrapper.executeWorkoutSampleQuery(predicate: workoutPredicate,
                                                     limit: HKObjectQueryNoLimit,
                                                     sortDescriptors: nil) { [weak self] _, workouts, error in
            guard let workouts = workouts else {
                Logger.traceError(message: "Failed to get workouts from observer update", error: error)
                completion()
                return
            }

            var fwfWorkouts = [Workout]()
            for workoutSample in workouts {
                let workout = Workout(workout: workoutSample)
                Logger.traceInfo(message: "Received workout update: \(workout.xtDictionary?.description ?? "nil")")

                fwfWorkouts.append(workout)
            }

            self?.activityDataService.reportWorkouts(fwfWorkouts) { [weak self] reportError in
                guard reportError == nil else {
                    Logger.traceError(message: "Failed to report workouts", error: error)
                    completion()
                    return
                }

                Logger.traceVerbose(message: "Successfully reported workouts")
                self?.storeLastUpdateTime(for: HealthKitManager.lastWorkoutUpdateKey, updateTime: Date())
                completion()
            }
        }
    }

    private func reportActivitySummaries(completion: @escaping () -> Void) {
        guard healthStoreWrapper.isHealthDataAvailable else {
            Logger.traceWarning(message: "Health data is not available on this device, not querying activity summaries")
            completion()
            return
        }

        let resultQueue = DispatchQueue(label: "reportActivitySummariesQueue")
        let dispatchGroup = DispatchGroup()

        // We are merging the results of several queries
        // This value will be set to true if any of the queries fails
        // but we may still have results from others that we will try to report to the backend
        var containsFailures = false

        var activitySummaries: [Date: ActivitySummaryDTO] = [:]
        dispatchGroup.enter()
        getActivitySummariesSinceLastUpdate { activityQuerySuccess, activityResults in
            resultQueue.sync {
                if !activityQuerySuccess {
                    containsFailures = true
                }

                let calendar = Calendar.current
                for activityResult in activityResults {
                    activitySummaries[activityResult.date] = activityResult
                }
            }

            dispatchGroup.leave()
        }

        var quantityResults: [HKQuantityTypeIdentifier: [Date: StatisticDTO]] = [:]
        for quantityType in HealthKitManager.quantityTypesToObserve {
            dispatchGroup.enter()
            getAllDailySumsSinceLastUpdate(for: quantityType) { success, result in
                resultQueue.sync {
                    if !success {
                        containsFailures = true
                    }

                    quantityResults[quantityType] = result
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .global()) {
            // Get all the dates that we have any data for
            var allDates = activitySummaries
                .keys
                .map { $0 }
            allDates.append(contentsOf: quantityResults.values.map { $0.keys }.joined() )

            var distinctDates = Array(Set(allDates))
            distinctDates.sort { $0 < $1 }

            var updatedActivitySummaries: [ActivitySummary] = []
            for date in distinctDates {
                // If we didn't get an ActivitySummary for this day, then create an empty one
                // We may have additional data for this date that isn't included in the HKActivitySummary
                let summaryDTO = activitySummaries[date] ?? ActivitySummaryDTO(date: date)
                var activitySummary = ActivitySummary(activitySummary: summaryDTO)

                // If we have any additional data for this day (step count, stairs climbed, etc.),
                // then add it to the ActivitySummary
                for quantityType in HealthKitManager.quantityTypesToObserve {
                    if let quantityResult = quantityResults[quantityType],
                       let quantity = quantityResult[date] {
                        activitySummary.updateStatistic(quantityType: quantityType, value: quantity)
                    }
                }

                updatedActivitySummaries.append(activitySummary)
            }

            self.activityDataService.reportActivitySummaries(updatedActivitySummaries) { error in
                defer {
                    completion()
                }

                guard error == nil else {
                    Logger.traceError(message: "Failed to report activity summaries", error: error)
                    return
                }

                // If we aren't sure that we got all the data from HealthKit properly,
                // then don't update the cached last update time so that we retry getting the data next time
                guard !containsFailures else {
                    Logger.traceWarning(message: "Successfully reported activity summaries, but there were errors in the HealthKit queries. Not updating last update time")
                    return
                }

                Logger.traceInfo(message: "Report activity summaries success, updating last update time")
                self.storeLastUpdateTime(for: HealthKitManager.lastActivityDataUpdateKey, updateTime: Date())
            }
        }
    }


    /// Returns all daily activity summaries since the last activity summary update
    /// - Parameter completion: Returns a tuple that indicates whether the query succeeded or not and any results
    private func getActivitySummariesSinceLastUpdate(completion: @escaping (Bool, [ActivitySummaryDTO]) -> Void) {
        // Get the activity summaries to report to the service
        let dateRange = getQueryDateRange(for: HealthKitManager.lastActivityDataUpdateKey)
        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: dateRange.startCompenents,
                                          end: dateRange.endComponents)

        let dateRangeDescription = "\(dateRange.startCompenents.date?.description ?? "nil") to \(dateRange.endComponents.date?.description ?? "nil")"
        Logger.traceInfo(message: "Executing activity summary query for dates \(dateRangeDescription)")
        healthStoreWrapper.executeActivitySummaryQuery(predicate: predicate) { _, summaries, error in
            guard let summaries = summaries else {
                Logger.traceError(message: "Failed to get activity summaries from observer update", error: error)
                completion(false, [])
                return
            }

            completion(true, summaries)
        }
    }

    
    /// Gets the sum of the given quantity for all days since the quantity was last updated in the backend
    /// - Parameters:
    ///   - quantityTypeId: The quantity to query in HealthKit
    ///   - completion: Returns a tuple of success and any results. Results may be returned even if the success bool is false, because only queries on some days might have failed
    private func getAllDailySumsSinceLastUpdate(for quantityTypeId: HKQuantityTypeIdentifier, completion: @escaping (Bool, [Date: StatisticDTO]) -> Void) {
        let calendar = Calendar.current
        var date = getLastUpdateTime(for: HealthKitManager.lastActivityDataUpdateKey)

        let dispatchGroup = DispatchGroup()
        let resultsQueue = DispatchQueue(label: "getAllDailySumsResultQueue_\(String(describing: quantityTypeId))")
        var results: [Date: StatisticDTO] = [:]
        var hasFailure = false

        // Loop through each day since the last update up to and including today
        // and query the sum for each day
        let today = Date()
        while date <= today {
            dispatchGroup.enter()
            getQuantityForDay(quantityTypeId: quantityTypeId, date: date) { error, statistics in
                defer {
                    dispatchGroup.leave()
                }

                guard let statistics = statistics else {
                    Logger.traceError(message: "Failed to get data for \(String(describing: quantityTypeId)) on \(date)",
                                      error: error)
                    resultsQueue.sync {
                        hasFailure = true
                    }
                    return
                }

                let startOfDay = calendar.startOfDay(for: date)
                resultsQueue.sync {
                    results[startOfDay] = statistics
                }
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else {
                Logger.traceError(message: "Could not add 1 day to \(date)")
                resultsQueue.sync {
                    hasFailure = true
                }
                break
            }

            date = nextDate
        }

        dispatchGroup.notify(queue: .global()) {
            completion(hasFailure, results)
        }
    }

    private func getQuantityForDay(quantityTypeId: HKQuantityTypeIdentifier, date: Date, completion: @escaping (Error?, StatisticDTO?) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(60 * 60 * 24 - 1) // Set end of day as 1 second before midnight

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay,
                                                    end: endOfDay,
                                                    options: [.strictStartDate, .strictEndDate])

        let dateRangeDescription = "\(startOfDay.description) to \(endOfDay.description)"
        Logger.traceInfo(message: "Executing query for \(String(describing: quantityTypeId)) in date range \(dateRangeDescription)")

        let hkUnitForType: HKUnit
        switch quantityTypeId {
        case .activeEnergyBurned:
            hkUnitForType = .largeCalorie()
        case .appleExerciseTime:
            hkUnitForType = .minute()
        case .distanceWalkingRunning:
            hkUnitForType = .meter()
        case .appleStandTime, .stepCount, .flightsClimbed:
            hkUnitForType = .count()
        default:
            completion(HttpError.generic, nil)
            return
        }

        healthStoreWrapper.executeStatisticsQuery(quantityType: HKQuantityType(quantityTypeId),
                                                  resultUnit: hkUnitForType,
                                                  quantitySamplePredicate: predicate,
                                                  options: .cumulativeSum) { _, statistics, error in
            if let error = error {
                Logger.traceError(message: "Failed to get data for \(String(describing: quantityTypeId)) on \(date)",
                                  error: error)
            }

            completion(error, statistics)
        }
    }

    private func storeLastUpdateTime(for key: String, updateTime: Date) {
        userDefaults.setValue(updateTime.timeIntervalSince1970, forKey: key)
    }

    private func getLastUpdateTime(for key: String) -> Date {
        let lastUpdate = userDefaults.double(forKey: key)

        let calendar = Calendar.current
        if lastUpdate > 0 {
            // The last update is stored in user defaults as the timeIntervalSince1970 value
            let date = Date(timeIntervalSince1970: lastUpdate)

            // Only query a max of 30 days of data
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: date)!
            if thirtyDaysAgo > date {
                Logger.traceWarning(message: "Last update for \(key) is more than thirty days ago. Only returning 30 days of data. Last update time: \(date). Thirty days ago is \(thirtyDaysAgo)")
                return thirtyDaysAgo
            }

            return date
        } else {
            // If we haven't received any health data before, default to querying the last 7 days
            return calendar.date(byAdding: .day, value: -7, to: Date())!
        }
    }

    private func getQueryDateRange(for key: String) -> (startCompenents: DateComponents, endComponents: DateComponents) {
        // Set the query end date to the distant future so we continue to receive updates after the app has launched and is sitting in memory
        let calendar = Calendar.current
        let queryStartDate = getLastUpdateTime(for: key)
        let queryEndDate = Date.distantFuture

        let dateComponents: Set<Calendar.Component> = [.day, .month, .year, .era]

        var startDateComponents = calendar.dateComponents(dateComponents, from: queryStartDate)
        startDateComponents.calendar = calendar

        var endDateComponents = calendar.dateComponents(dateComponents, from: queryEndDate)
        endDateComponents.calendar = calendar

        return (startDateComponents, endDateComponents)
    }
}
