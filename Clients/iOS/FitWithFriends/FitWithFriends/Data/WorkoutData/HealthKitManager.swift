//
//  HealthKitManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/20.
//

import Combine
import Foundation
import HealthKit

class HealthKitManager {
    private let authenticationManager: AuthenticationManager
    private let userDefaults: UserDefaults

    private let hkHealthStore = HKHealthStore()

    private static let healthPromptKey = "HasPromptedForHealthPermissions"
    private static let lastUpdateKey = "LastHealthDataUpdate"
    private static let lastWorkoutAnchorKey = "LastWorkoutAnchor"

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

    init(authenticationManager: AuthenticationManager,
         userDefaults: UserDefaults) {
        self.authenticationManager = authenticationManager
        self.userDefaults = userDefaults
    }

    func requestHealthKitPermission(completion: @escaping () -> Void) {
        guard shouldPromptUser else {
            Logger.traceInfo(message: "User has already been prompted for health permissions, not prompting again")
            return
        }

        let dataTypes: [HKObjectType] = [
            .workoutType(),
            .activitySummaryType()
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
                self?.registerForBackgroundUpdates()
            }

            completion()
        }
    }

    func registerForBackgroundUpdates() {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.traceWarning(message: "Health data is not available on this device, not registering for background updates")
            return
        }

        hkHealthStore.enableBackgroundDelivery(for: .activitySummaryType(), frequency: .hourly) { success, error in
            if let error = error {
                Logger.traceError(message: "Failed to enable background delivery for activity summary", error: error)
            }

            Logger.traceInfo(message: "Enabled background delivery for activity summary: \(success)")
        }

        hkHealthStore.enableBackgroundDelivery(for: .workoutType(), frequency: .immediate) { success, error in
            if let error = error {
                Logger.traceError(message: "Failed to enable background delivery for workouts", error: error)
            }

            Logger.traceInfo(message: "Enabled background delivery for workouts: \(success)")
        }
    }

    func registerDataQueries() {
        registerActivitySummaryQuery()
        registerWorkoutQuery()
    }

    private func registerActivitySummaryQuery() {
        let dateRange = getQueryDateRange()
        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: dateRange.startCompenents,
                                          end: dateRange.endComponents)

        Logger.traceInfo(message: "Executing activity summary query for dates \(dateRange.startCompenents.description) to \(dateRange.endComponents.description)")
        let query = HKActivitySummaryQuery(predicate: predicate, resultsHandler: handleActivitySummaryData(query:summaries:error:))
        query.updateHandler = handleActivitySummaryData(query:summaries:error:)
        hkHealthStore.execute(query)
    }

    private func registerWorkoutQuery() {
        var anchor: HKQueryAnchor?
        if let previousAnchorData = userDefaults.data(forKey: HealthKitManager.lastWorkoutAnchorKey),
           let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: previousAnchorData),
           let previousAnchor = unarchiver.decodeObject() as? HKQueryAnchor {
            anchor = previousAnchor
        }

        let query = HKAnchoredObjectQuery(type: .workoutType(), predicate: nil, anchor: anchor, limit: HKObjectQueryNoLimit, resultsHandler: handleWorkoutData(query:workouts:deletedObjects:anchor:error:))
        query.updateHandler = handleWorkoutData(query:workouts:deletedObjects:anchor:error:)
        hkHealthStore.execute(query)
    }

    private func handleActivitySummaryData(query: HKQuery, summaries: [HKActivitySummary]?, error: Error?) {
        if let error = error {
            Logger.traceError(message: "Error when querying activity summary data", error: error)
            return
        }

        Logger.traceInfo(message: "Received activity summary update with \(summaries?.count ?? 0) new summaries")

        userDefaults.setValue(Date().timeIntervalSince1970, forKey: HealthKitManager.lastUpdateKey)
        if let summaries = summaries {
            for summary in summaries {
                // TODO: send to service
                print(summary.description)
            }
        }
    }

    private func handleWorkoutData(query: HKAnchoredObjectQuery, workouts: [HKSample]?, deletedObjects: [HKDeletedObject]?, anchor: HKQueryAnchor?, error: Error?) {
        if let error = error {
            Logger.traceError(message: "Error when querying workout data", error: error)
            return
        }

        Logger.traceInfo(message: "Received workout update with \(workouts?.count ?? 0) new workouts")

        if let anchor = anchor {
            let archiver = NSKeyedArchiver(requiringSecureCoding: true)
            archiver.encode(anchor)

            userDefaults.setValue(archiver.encodedData, forKey: HealthKitManager.lastWorkoutAnchorKey)
        }

        if let workouts = workouts {
            for workoutSample in workouts {
                guard let workout = workoutSample as? HKWorkout else {
                    Logger.traceWarning(message: "Sample was not a workout type, it was \(type(of: workoutSample))")
                    continue
                }

                // TODO: send to service
                print(workout.description)
            }
        }
    }

    private func getQueryDateRange() -> (startCompenents: DateComponents, endComponents: DateComponents) {
        // Set the query end date to a month in the future so we continue to receive updates after the app has launched and is sitting in memory
        let calendar = Calendar.current
        let queryStartDate: Date
        let queryEndDate = calendar.date(byAdding: .day, value: 30, to: Date())!

        let lastUpdate = userDefaults.double(forKey: HealthKitManager.lastUpdateKey)
        if lastUpdate > 0 {
            // The last update is stored in user defaults as the timeIntervalSince1970 value
            queryStartDate = Date(timeIntervalSince1970: lastUpdate)
        } else {
            // If we haven't received any health data before, default to querying the last 7 days
            queryStartDate = calendar.date(byAdding: .day, value: -7, to: queryEndDate)!
        }

        let dateComponents: Set<Calendar.Component> = [.day, .month, .year, .era]

        var startDateComponents = calendar.dateComponents(dateComponents, from: queryStartDate)
        startDateComponents.calendar = calendar

        var endDateComponents = calendar.dateComponents(dateComponents, from: queryEndDate)
        endDateComponents.calendar = calendar

        return (startDateComponents, endDateComponents)
    }
}
