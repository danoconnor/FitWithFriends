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
    private static let lastUpdateKey = "LastHealthDataUpdate"
    private static let lastKnownCalorieGoalKey = "LastKnownCalorieGoal"
    private static let lastKnownExerciseGoalKey = "LastKnownExerciseGoal"
    private static let lastKnownStandGoalKey = "LastKnownStandGoal"

    private static let backgroundTaskTimeout: TimeInterval = 60 // 60 seconds

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
                    self?.reportActivitySummaries(completion: nil)
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

        let dataTypes: [HKObjectType] = [
            .workoutType(),
            .activitySummaryType(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.appleStandTime)
        ]

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

    /// Register for hourly background updates for calorie, exercise, and stand data
    private func registerForBackgroundUpdates() {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.traceWarning(message: "Health data is not available on this device, not registering for background updates")
            return
        }

        let backgroundQuantityTypes = [
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.appleStandTime)
        ]

        for quantityType in backgroundQuantityTypes {
            hkHealthStore.enableBackgroundDelivery(for: quantityType,
                                                      frequency: .hourly) { success, error in
                if let error = error {
                    Logger.traceError(message: "Failed to enable background delivery for \(quantityType)", error: error)
                }

                Logger.traceInfo(message: "Enabled background delivery for \(quantityType): \(success)")
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

        let queryDescriptors = [
            HKQueryDescriptor(sampleType: HKQuantityType(.activeEnergyBurned), predicate: nil),
            HKQueryDescriptor(sampleType: HKQuantityType(.appleExerciseTime), predicate: nil),
            HKQueryDescriptor(sampleType: HKQuantityType(.appleStandTime), predicate: nil)
        ]

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

        Logger.traceInfo(message: "Received observer query update")
        activitySummaryQueue.async { [weak self] in
            self?.reportActivitySummaries(completion: completion)
        }
    }

    private func reportActivitySummaries(completion: HKObserverQueryCompletionHandler?) {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.traceWarning(message: "Health data is not available on this device, not querying activity summaries")
            completion?()
            return
        }

        // Get the activity summaries to report to the service
        let dateRange = getQueryDateRange()
        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: dateRange.startCompenents,
                                          end: dateRange.endComponents)

        let dateRangeDescription = "\(dateRange.startCompenents.date?.description ?? "nil") to \(dateRange.endComponents.date?.description ?? "nil")"
        Logger.traceInfo(message: "Executing activity summary query for dates \(dateRangeDescription)")
        let activitySummaryQuery = HKActivitySummaryQuery(predicate: predicate) { [weak self] _, summaries, error in
            guard let summaries = summaries else {
                Logger.traceError(message: "Failed to get activity summaries from observer update", error: error)
                completion?()
                return
            }

            let dispatchGroup = DispatchGroup()
            var reportActivitySummarySuccess = true

            for summary in summaries {
                guard let activitySummary = ActivitySummary(activitySummary: summary) else {
                    Logger.traceWarning(message: "Could not create activity summary object")
                    continue
                }

                let activitySummaryDescritpion = activitySummary.xtDictionary?.description ?? "nil"
                Logger.traceInfo(message: "Received activity summary update: \(activitySummaryDescritpion)")

                dispatchGroup.enter()
                self?.activityDataService.reportActivitySummary(activitySummary: activitySummary) { reportActivitySummaryError in
                    if let reportActivitySummaryError = reportActivitySummaryError {
                        Logger.traceError(message: "Failed to report activity summary: \(activitySummaryDescritpion)", error: reportActivitySummaryError)
                        reportActivitySummarySuccess = false
                    }

                    dispatchGroup.leave()
                }
            }

            let dispatchGroupResult = dispatchGroup.wait(timeout: .now() + HealthKitManager.backgroundTaskTimeout)
            if dispatchGroupResult != .success {
                Logger.traceError(message: "Dispatch group timed out")
                reportActivitySummarySuccess = false
            }

            if reportActivitySummarySuccess {
                // If we successfully reported all new activity summaries,
                // then save a new anchor date so we don't report them again
                self?.userDefaults.setValue(Date().timeIntervalSince1970, forKey: HealthKitManager.lastUpdateKey)
                self?.activityUpdateDelegate.activityDataUpdated()
            }

            Logger.traceInfo(message: "Finished observer query update for dates \(dateRangeDescription). Summary count: \(summaries.count). Result: \(reportActivitySummarySuccess)")
            completion?()
        }

        hkHealthStore.execute(activitySummaryQuery)
    }

    private func getQueryDateRange() -> (startCompenents: DateComponents, endComponents: DateComponents) {
        // Set the query end date to the distant future so we continue to receive updates after the app has launched and is sitting in memory
        let calendar = Calendar.current
        let queryStartDate: Date
        let queryEndDate = Date.distantFuture

        let lastUpdate = userDefaults.double(forKey: HealthKitManager.lastUpdateKey)
        if lastUpdate > 0 {
            // The last update is stored in user defaults as the timeIntervalSince1970 value
            queryStartDate = Date(timeIntervalSince1970: lastUpdate)
        } else {
            // If we haven't received any health data before, default to querying the last 7 days
            queryStartDate = calendar.date(byAdding: .day, value: -7, to: Date())!
        }

        let dateComponents: Set<Calendar.Component> = [.day, .month, .year, .era]

        var startDateComponents = calendar.dateComponents(dateComponents, from: queryStartDate)
        startDateComponents.calendar = calendar

        var endDateComponents = calendar.dateComponents(dateComponents, from: queryEndDate)
        endDateComponents.calendar = calendar

        return (startDateComponents, endDateComponents)
    }
}
