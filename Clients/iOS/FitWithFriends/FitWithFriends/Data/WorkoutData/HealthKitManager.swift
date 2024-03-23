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

class HealthKitManager {
    private let activityDataService: ActivityDataService
    private let activityUpdateDelegate: ActivityUpdateDelegate
    private let authenticationManager: AuthenticationManager
    private let userDefaults: UserDefaults

    private let hkHealthStore = HKHealthStore()
    private let activitySummaryQueue = DispatchQueue(label: "ActivitySummaryQueue")

    // User defaults keys
    private static let healthPromptKey = "HasPromptedForHealthPermissions"
    private static let lastKnownCalorieGoalKey = "LastKnownCalorieGoal"
    private static let lastKnownExerciseGoalKey = "LastKnownExerciseGoal"
    private static let lastKnownStandGoalKey = "LastKnownStandGoal"
    private static let lastActivityDataUpdateKey = "LastActivityDataUpdate"
    private static let lastWorkoutUpdateKey = "LastWorkoutUpdate"

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

    var shouldPromptUser: Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.traceWarning(message: "Health data is not available on this device. Should not prompt user for permissions")
            return false
        }

        // Apple does not provide a way to check the current health permissions,
        // so the best we can do is check if we've shown the prompt before
        return userDefaults.bool(forKey: HealthKitManager.healthPromptKey) != true
    }

    var lastKnownCalorieGoal: Double {
        userDefaults.double(forKey: HealthKitManager.lastKnownCalorieGoalKey)
    }

    var lastKnownExerciseGoal: Double {
        userDefaults.double(forKey: HealthKitManager.lastKnownExerciseGoalKey)
    }

    var lastKnownStandGoal: Double {
        userDefaults.double(forKey: HealthKitManager.lastKnownStandGoalKey)
    }

    init(activityDataService: ActivityDataService,
         activityUpdateDelegate: ActivityUpdateDelegate,
         authenticationManager: AuthenticationManager,
         userDefaults: UserDefaults) {
        self.activityDataService = activityDataService
        self.activityUpdateDelegate = activityUpdateDelegate
        self.authenticationManager = authenticationManager
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

    func requestHealthKitPermission(completion: @escaping () -> Void) {
        guard shouldPromptUser else {
            Logger.traceInfo(message: "User has already been prompted for health permissions, not prompting again")
            return
        }

        var dataTypes: [HKObjectType] = [
            .workoutType(),
            .activitySummaryType()
        ]
        dataTypes.append(contentsOf: HealthKitManager.quantityTypesToObserve.map { HKQuantityType($0) })

        hkHealthStore.requestAuthorization(toShare: nil, read: Set(dataTypes)) { [weak self] success, error in
            if let error = error {
                Logger.traceError(message: "Failed to request authorization for health data", error: error)
                completion()
                return
            }

            Logger.traceInfo(message: "Request authorization for health data success: \(success)")

            if success {
                self?.userDefaults.set(true, forKey: HealthKitManager.healthPromptKey)
                self?.setupQueries()
            }

            completion()
        }
    }

    func setupQueries() {
        registerObserverQueries()
        registerForBackgroundUpdates()
    }

    func getCurrentActivitySummary(completion: @escaping (HKActivitySummary?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.traceWarning(message: "Health data is not available on this device, can't query current activity summary")
            completion(nil)
            return
        }

        let calendar = Calendar.current
        var today = calendar.dateComponents([.day, .month, .year, .era], from: Date())
        today.calendar = calendar

        let predicate = HKQuery.predicateForActivitySummary(with: today)

        let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
            if let error = error {
                Logger.traceError(message: "Failed to get activity summary", error: error)
                completion(nil)
                return
            }

            let summary = summaries?.first { $0.dateComponents(for: calendar) == today }

            // Update our last known goals if we were able to successfully get the summary
            // These are used when there is no data for the current day so we can show the empty rings on the homepage
            if let summary = summary {
                self.userDefaults.set(summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()), forKey: HealthKitManager.lastKnownCalorieGoalKey)
                self.userDefaults.set(summary.appleExerciseTimeGoal.doubleValue(for: .minute()), forKey: HealthKitManager.lastKnownExerciseGoalKey)
                self.userDefaults.set(summary.appleStandHoursGoal.doubleValue(for: .count()), forKey: HealthKitManager.lastKnownStandGoalKey)
            }

            completion(summary)
        }

        hkHealthStore.execute(query)
    }

    /// Register for hourly background updates for calorie, exercise, stand, steps, distance, and flights climbed
    private func registerForBackgroundUpdates() {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.traceWarning(message: "Health data is not available on this device, not registering for background updates")
            return
        }

        for quantityType in HealthKitManager.quantityTypesToObserve {
            hkHealthStore.enableBackgroundDelivery(for: HKQuantityType(quantityType),
                                                   frequency: .hourly) { success, error in
                if let error = error {
                    Logger.traceError(message: "Failed to enable background delivery for \(quantityType)", error: error)
                } else {
                    Logger.traceInfo(message: "Enabled background delivery for \(quantityType): \(success)")
                }
            }
        }

        // Register for background updates when a workout completes
        hkHealthStore.enableBackgroundDelivery(for: .workoutType(), 
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
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.traceWarning(message: "Health data is not available on this device, not registering data queries")
            return
        }

        var queryDescriptors = [
            HKQueryDescriptor(sampleType: HKObjectType.workoutType(), predicate: nil)
        ]
        queryDescriptors.append(contentsOf: HealthKitManager.quantityTypesToObserve.map {
            HKQueryDescriptor(sampleType: HKQuantityType($0), predicate: nil)
        })

        let query = HKObserverQuery(queryDescriptors: queryDescriptors,
                                    updateHandler: observerQueryUpdateHandler(query:samples:completion:error:))
        hkHealthStore.execute(query)

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
        }
    }

    private func reportWorkouts(completion: @escaping () -> Void) {
        // Query for the workouts that have been added since the last update
        let dateRange = getQueryDateRange(for: HealthKitManager.lastWorkoutUpdateKey)
        let workoutActivityPredicate = HKQuery.predicateForWorkoutActivities(start: dateRange.startCompenents.date,
                                                                             end: dateRange.endComponents.date)
        let workoutPredicate = HKQuery.predicateForWorkouts(activityPredicate: workoutActivityPredicate)

        let workoutQuery = HKSampleQuery(sampleType: HKObjectType.workoutType(),
                                         predicate: workoutPredicate,
                                         limit: HKObjectQueryNoLimit,
                                         sortDescriptors: nil) { [weak self] _, workouts, error in
            guard let workouts = workouts else {
                Logger.traceError(message: "Failed to get workouts from observer update", error: error)
                completion()
                return
            }

            var fwfWorkouts = [Workout]()
            for workoutSample in workouts {
                guard let hkWorkout = workoutSample as? HKWorkout else {
                    Logger.traceWarning(message: "Could not create workout object")
                    continue
                }

                let workout = Workout(workout: hkWorkout)
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
        hkHealthStore.execute(workoutQuery)
    }

    private func reportActivitySummaries(completion: () -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
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

        var activitySummaries: [Date: HKActivitySummary] = [:]
        dispatchGroup.enter()
        getActivitySummaries { activityQuerySuccess, activityResults in
            resultQueue.sync {
                if !activityQuerySuccess {
                    containsFailures = true
                }

                let calendar = Calendar.current
                for activityResult in activityResults {
                    guard let activityDate = activityResult.dateComponents(for: calendar).date else {
                        Logger.traceWarning(message: "Could not get date for activity!")
                        continue
                    }

                    activitySummaries[activityDate] = activityResult
                }
            }

            dispatchGroup.leave()
        }

        var quantityResults: [HKQuantityTypeIdentifier: [Date: HKStatistics]] = [:]
        for quantityType in HealthKitManager.quantityTypesToObserve {
            dispatchGroup.enter()
            getAllDailySumsSinceLastUpdate(for: quantityType) { success, result in
                resultQueue.sync {
                    containsFailures = true
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
                var activitySummary: ActivitySummary
                if let hkSummary = activitySummaries[date],
                   let fwfActivitySummary = ActivitySummary(activitySummary: hkSummary) {
                    activitySummary = fwfActivitySummary
                } else {
                    activitySummary = ActivitySummary(date: date)
                }

                for quantityType in HealthKitManager.quantityTypesToObserve {
                    if let quantityResult = quantityResults[quantityType],
                       let quantity = quantityResult[date] {
                        activitySummary.updateStatistic(quantityType: quantityType, value: quantity)
                    }
                }

                updatedActivitySummaries.append(activitySummary)
            }

            self.activityDataService.reportActivitySummaries(updatedActivitySummaries) { error in
                guard error == nil else {
                    Logger.traceError(message: "Failed to report activity summaries", error: error)
                    return
                }

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
    private func getActivitySummaries(completion: @escaping (Bool, [HKActivitySummary]) -> Void) {
        // Get the activity summaries to report to the service
        let dateRange = getQueryDateRange(for: HealthKitManager.lastActivityDataUpdateKey)
        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: dateRange.startCompenents,
                                          end: dateRange.endComponents)

        let dateRangeDescription = "\(dateRange.startCompenents.date?.description ?? "nil") to \(dateRange.endComponents.date?.description ?? "nil")"
        Logger.traceInfo(message: "Executing activity summary query for dates \(dateRangeDescription)")
        let activitySummaryQuery = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
            guard let summaries = summaries else {
                Logger.traceError(message: "Failed to get activity summaries from observer update", error: error)
                completion(false, [])
                return
            }

            completion(true, summaries)
        }

        hkHealthStore.execute(activitySummaryQuery)
    }

    
    /// Gets the sum of the given quantity for all days since the quantity was last updated in the backend
    /// - Parameters:
    ///   - quantityTypeId: The quantity to query in HealthKit
    ///   - completion: Returns a tuple of success and any results. Results may be returned even if the success bool is false, because only queries on some days might have failed
    private func getAllDailySumsSinceLastUpdate(for quantityTypeId: HKQuantityTypeIdentifier, completion: @escaping (Bool, [Date: HKStatistics]) -> Void) {
        let calendar = Calendar.current
        var date = getLastUpdateTime(for: HealthKitManager.lastActivityDataUpdateKey)

        let dispatchGroup = DispatchGroup()
        let resultsQueue = DispatchQueue(label: "getAllDailySumsResultQueue_\(String(describing: quantityTypeId))")
        var results: [Date: HKStatistics] = [:]
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

    private func getQuantityForDay(quantityTypeId: HKQuantityTypeIdentifier, date: Date, completion: @escaping (Error?, HKStatistics?) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(60 * 60 * 24 - 1) // Set end of day as 1 second before midnight

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay,
                                                    end: endOfDay,
                                                    options: [.strictStartDate, .strictEndDate])

        let dateRangeDescription = "\(startOfDay.description) to \(endOfDay.description)"
        Logger.traceInfo(message: "Executing query for \(String(describing: quantityTypeId)) in date range \(dateRangeDescription)")

        let query = HKStatisticsQuery(quantityType: HKQuantityType(quantityTypeId), quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
            if let error = error {
                Logger.traceError(message: "Failed to get data for \(String(describing: quantityTypeId)) on \(date)",
                                  error: error)
            }

            completion(error, statistics)
        }
        hkHealthStore.execute(query)
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
