//
//  HealthKitManagerTests.swift
//  FitWithFriends_UnitTests
//
//  Created by Dan O'Connor on 3/26/24.
//

import Foundation
import Fit_with_Friends

import XCTest
import HealthKit

final class HealthKitManagerTests: XCTestCase {
    private var healthKitManager: HealthKitManager!

    private var activityDataService: MockActivityDataService!
    private var activityUpdateDelegate: MockActivityUpdateDelegate!
    private var authenticationManager: MockAuthenticationManager!
    private var healthStoreWrapper: MockHealthStoreWrapper!
    private var userDefaults: UserDefaults!

    override func setUp() {
        activityDataService = MockActivityDataService()
        activityUpdateDelegate = MockActivityUpdateDelegate()
        authenticationManager = MockAuthenticationManager()
        healthStoreWrapper = MockHealthStoreWrapper()
        userDefaults = UserDefaults.standard

        healthKitManager = HealthKitManager(activityDataService: activityDataService, 
                                            activityUpdateDelegate: activityUpdateDelegate,
                                            authenticationManager: authenticationManager,
                                            healthStoreWrapper: healthStoreWrapper,
                                            userDefaults: userDefaults)
    }

    override func tearDown() {
        // Reset any user defaults keys that were changed
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }

    func test_requestHealthKitPermission_shouldNotPrompt() {
        // Set the bool saying that we have already prompted the user
        userDefaults.setValue(true, forKey: HealthKitManager.healthPromptKey)
        XCTAssertFalse(healthKitManager.shouldPromptUser, "Should not prompt user")

        let expectation = expectation(description: "completion called")
        healthKitManager.requestHealthKitPermission {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Validate that we didn't send any data to the requestAuthorization,
        // which shows that we did not call it
        XCTAssertNil(healthStoreWrapper.param_typesToRead, "Should not have called HealthStore")
    }

    func test_requestHealthKitPermission_error() {
        healthStoreWrapper.return_authorizationError = HttpError.generic

        let expectation = expectation(description: "completion called")
        healthKitManager.requestHealthKitPermission {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)

        // Validate that we should still attempt a prompt on next launch
        XCTAssertTrue(healthKitManager.shouldPromptUser, "Should still prompt user because we did not prompt successfully")
    }

    func test_requestHealthKitPermission_success() {
        healthStoreWrapper.return_authorizationSuccess = true

        let expectation = expectation(description: "completion called")
        healthKitManager.requestHealthKitPermission {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)

        // Validate the types that we wanted to read from HealthKit
        XCTAssertNotNil(healthStoreWrapper.param_typesToRead, "Should have requested data to read")
        XCTAssertEqual(healthStoreWrapper.param_typesToRead!.count, 8)
        XCTAssertTrue(healthStoreWrapper.param_typesToRead!.contains(.workoutType()))
        XCTAssertTrue(healthStoreWrapper.param_typesToRead!.contains(.activitySummaryType()))
        XCTAssertTrue(healthStoreWrapper.param_typesToRead!.contains(HKQuantityType(.activeEnergyBurned)))
        XCTAssertTrue(healthStoreWrapper.param_typesToRead!.contains(HKQuantityType(.appleExerciseTime)))
        XCTAssertTrue(healthStoreWrapper.param_typesToRead!.contains(HKQuantityType(.appleStandTime)))
        XCTAssertTrue(healthStoreWrapper.param_typesToRead!.contains(HKQuantityType(.stepCount)))
        XCTAssertTrue(healthStoreWrapper.param_typesToRead!.contains(HKQuantityType(.distanceWalkingRunning)))
        XCTAssertTrue(healthStoreWrapper.param_typesToRead!.contains(HKQuantityType(.flightsClimbed)))
        XCTAssertNil(healthStoreWrapper.param_typesToShare, "Should not request writing any data to HealthKit")

        // Validate that we won't try to prompt the user multiple times
        XCTAssertFalse(healthKitManager.shouldPromptUser, "Should not prompt user again because we successfully prompted")

        // Validate that we setup the observer query and background updates
        XCTAssertNotNil(healthStoreWrapper.return_observerQuery, "Should have setup the observer query")
        XCTAssertNotNil(healthStoreWrapper.param_backgroundDelivery_type, "Should have registered for background updates")
    }

    func test_setupObserverQueries_validateBackgroundUpdates() {
        healthKitManager.setupObserverQueries()

        // Validate that we requested background updates for all the types we care about
        XCTAssertEqual(healthStoreWrapper.requestedBackgroundTypes.count, 6)
        XCTAssertTrue(healthStoreWrapper.requestedBackgroundTypes.contains(where: { $0.type == .workoutType() && $0.frequency == .immediate }))
        XCTAssertTrue(healthStoreWrapper.requestedBackgroundTypes.contains(where: { $0.type == HKQuantityType(.stepCount) && $0.frequency == .hourly }))
        XCTAssertTrue(healthStoreWrapper.requestedBackgroundTypes.contains(where: { $0.type == HKQuantityType(.distanceWalkingRunning) && $0.frequency == .hourly }))
        XCTAssertTrue(healthStoreWrapper.requestedBackgroundTypes.contains(where: { $0.type == HKQuantityType(.flightsClimbed) && $0.frequency == .hourly }))
        XCTAssertTrue(healthStoreWrapper.requestedBackgroundTypes.contains(where: { $0.type == HKQuantityType(.appleExerciseTime) && $0.frequency == .hourly }))
        XCTAssertTrue(healthStoreWrapper.requestedBackgroundTypes.contains(where: { $0.type == HKQuantityType(.activeEnergyBurned) && $0.frequency == .hourly }))
    }

    func test_setupObserverQueries_validateObserverQueries() {
        healthKitManager.setupObserverQueries()

        // Validate that we requested observer updates for all the types we care about
        XCTAssertNotNil(healthStoreWrapper.param_queryDescriptors)
        XCTAssertNotNil(healthStoreWrapper.param_updateHandler)

        XCTAssertTrue(healthStoreWrapper.param_queryDescriptors!.contains(where: { $0.sampleType == .workoutType() }))
        XCTAssertTrue(healthStoreWrapper.param_queryDescriptors!.contains(where: { $0.sampleType == HKQuantityType(.stepCount) }))
        XCTAssertTrue(healthStoreWrapper.param_queryDescriptors!.contains(where: { $0.sampleType == HKQuantityType(.distanceWalkingRunning) }))
        XCTAssertTrue(healthStoreWrapper.param_queryDescriptors!.contains(where: { $0.sampleType == HKQuantityType(.flightsClimbed) }))
    }

    func test_setupObserverQueries_updateHandler() {
        // Setup data to be returned from HealthKit
        let activitySummary = ActivitySummaryDTO(date: Date(),
                                                 activeEnergyBurned: 250,
                                                 activeEnergyBurnedGoal: 500,
                                                 appleExerciseTime: 15,
                                                 appleExerciseTimeGoal: 30,
                                                 appleStandHours: 6,
                                                 appleStandHoursGoal: 12)
        healthStoreWrapper.return_activitySummaryQuery_activitySummaries = [activitySummary]

        let workout = WorkoutSampleDTO(startDate: Date(),
                                       duration: 60 * 15,
                                       caloriesBurned: 200,
                                       activityType: .running,
                                       distance: 3,
                                       unit: .mile)
        healthStoreWrapper.return_sampleQuery_samples = [workout]

        healthKitManager.setupObserverQueries()

        // Call the update handler and validate that we get the latest data and report it
        XCTAssertNotNil(healthStoreWrapper.param_updateHandler)

        let updateCompletionCalledExpectation = expectation(description: "Update handler completion block should be called")
        healthStoreWrapper.param_updateHandler!(healthStoreWrapper.return_observerQuery!, Set(arrayLiteral: .workoutType(), .quantityType(forIdentifier: .activeEnergyBurned)!), {
            updateCompletionCalledExpectation.fulfill()
        }, nil)

        waitForExpectations(timeout: 5)

        // Validate that we sent the expected data to the backend
        guard let reportedActivitySummary = activityDataService.param_reportActivitySummaries_activitySummaries?.first else {
            XCTFail("Did not report any activity summaries")
            return
        }

        XCTAssertEqual(reportedActivitySummary.date, activitySummary.date)
        XCTAssertEqual(reportedActivitySummary.activeCaloriesBurned, activitySummary.activeEnergyBurned)
        XCTAssertEqual(reportedActivitySummary.activeCaloriesGoal, activitySummary.activeEnergyBurnedGoal)
        XCTAssertEqual(reportedActivitySummary.exerciseTime, activitySummary.appleExerciseTime)
        XCTAssertEqual(reportedActivitySummary.exerciseTimeGoal, activitySummary.appleExerciseTimeGoal)
        XCTAssertEqual(reportedActivitySummary.standTime, activitySummary.appleStandHours)
        XCTAssertEqual(reportedActivitySummary.standTimeGoal, activitySummary.appleStandHoursGoal)

        guard let reportedWorkout = activityDataService.param_reportWorkouts_workouts?.first else {
            XCTFail("Did not report any workouts")
            return
        }

        XCTAssertEqual(reportedWorkout.startDate, workout.startDate)
        XCTAssertEqual(reportedWorkout.duration, workout.duration)
        XCTAssertEqual(reportedWorkout.activityType, workout.activityType)
        XCTAssertEqual(reportedWorkout.caloriesBurned, workout.caloriesBurned)
        XCTAssertEqual(reportedWorkout.distance, workout.distance)
        XCTAssertEqual(reportedWorkout.unit, workout.unit)
    }

    /// Verifies that a step count reported by HealthKit statistics actually appears in the
    /// ActivitySummary that reaches the backend.  This is the end-to-end test that was
    /// missing when the closure-capture date bug was introduced: `test_setupObserverQueries_updateHandler`
    /// checked ring-data fields (calories, exercise, stand) but never asserted on `stepCount`,
    /// so the bug was invisible until a user noticed wrong numbers in production.
    func test_setupObserverQueries_updateHandler_stepCountPropagatesIntoReportedSummary() {
        // Use a 2-day window (yesterday → today) so the stats loop is short and deterministic.
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        userDefaults.set(yesterday.timeIntervalSince1970, forKey: HealthKitManager.lastActivityDataUpdateKey)

        // Use startOfDay so the activity-summary key matches the statistics results keys.
        // Real HKActivitySummary dates are always start-of-day; tests should mirror that.
        let todayStart = calendar.startOfDay(for: Date())

        let expectedStepCount: UInt = 5_432
        healthStoreWrapper.return_statisticsQuery_statistics = [
            HKQuantityType(.stepCount): StatisticDTO(sumValue: expectedStepCount)
        ]

        let todayActivitySummary = ActivitySummaryDTO(date: todayStart,
                                                       activeEnergyBurned: 300,
                                                       activeEnergyBurnedGoal: 500,
                                                       appleExerciseTime: 20,
                                                       appleExerciseTimeGoal: 30,
                                                       appleStandHours: 8,
                                                       appleStandHoursGoal: 12)
        healthStoreWrapper.return_activitySummaryQuery_activitySummaries = [todayActivitySummary]

        healthKitManager.setupObserverQueries()
        XCTAssertNotNil(healthStoreWrapper.param_updateHandler)

        let completionExpectation = expectation(description: "Observer update handler should call its completion block")
        healthStoreWrapper.param_updateHandler!(
            healthStoreWrapper.return_observerQuery!,
            Set([HKQuantityType(.stepCount)]),
            { completionExpectation.fulfill() },
            nil
        )

        waitForExpectations(timeout: 10)

        guard let reportedSummaries = activityDataService.param_reportActivitySummaries_activitySummaries else {
            XCTFail("No activity summaries were reported to the backend")
            return
        }

        let todaySummary = reportedSummaries.first { calendar.startOfDay(for: $0.date) == todayStart }

        XCTAssertNotNil(todaySummary, "Expected a reported activity summary for today")
        XCTAssertEqual(todaySummary?.stepCount, expectedStepCount,
                       "Step count from HealthKit statistics should appear in the reported summary")
    }

    /// Verifies that a multi-day sync window (3 days) reports exactly one summary per day,
    /// each dated on its own correct day, with step counts correctly attributed rather than
    /// all collapsed under a single (wrong) date.
    ///
    /// With the closure-capture bug, all three callbacks would have written to `results[tomorrow]`,
    /// producing one spurious future-dated entry instead of three properly-dated entries.
    func test_setupObserverQueries_updateHandler_multiDayWindowReportsAllDates() {
        let calendar = Calendar.current

        // 3-day window: 2 days ago, yesterday, today
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        userDefaults.set(twoDaysAgo.timeIntervalSince1970, forKey: HealthKitManager.lastActivityDataUpdateKey)

        let expectedStepCount: UInt = 4_000
        healthStoreWrapper.return_statisticsQuery_statistics = [
            HKQuantityType(.stepCount): StatisticDTO(sumValue: expectedStepCount)
        ]

        // Use startOfDay so the activity-summary key matches the statistics results keys.
        // Real HKActivitySummary dates are always start-of-day; tests should mirror that.
        let todayStart = calendar.startOfDay(for: Date())
        let todayActivitySummary = ActivitySummaryDTO(date: todayStart,
                                                       activeEnergyBurned: 300,
                                                       activeEnergyBurnedGoal: 500,
                                                       appleExerciseTime: 20,
                                                       appleExerciseTimeGoal: 30,
                                                       appleStandHours: 8,
                                                       appleStandHoursGoal: 12)
        healthStoreWrapper.return_activitySummaryQuery_activitySummaries = [todayActivitySummary]

        healthKitManager.setupObserverQueries()
        XCTAssertNotNil(healthStoreWrapper.param_updateHandler)

        let completionExpectation = expectation(description: "Observer update handler should call its completion block")
        healthStoreWrapper.param_updateHandler!(
            healthStoreWrapper.return_observerQuery!,
            Set([HKQuantityType(.stepCount)]),
            { completionExpectation.fulfill() },
            nil
        )

        waitForExpectations(timeout: 10)

        guard let reportedSummaries = activityDataService.param_reportActivitySummaries_activitySummaries else {
            XCTFail("No activity summaries were reported to the backend")
            return
        }

        // No summary should be dated in the future
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        let futureSummaries = reportedSummaries.filter { calendar.startOfDay(for: $0.date) >= tomorrow }
        XCTAssertTrue(futureSummaries.isEmpty,
                      "No summary should be dated in the future; found: \(futureSummaries.map { $0.date })")

        // All three days in the window should be represented
        XCTAssertEqual(reportedSummaries.count, 3,
                       "Expected exactly 3 summaries for the 3-day window, got \(reportedSummaries.count)")

        let twoDaysAgoStart = calendar.startOfDay(for: twoDaysAgo)
        let yesterdayStart  = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: Date())!)

        let twoDaysAgoSummary = reportedSummaries.first { calendar.startOfDay(for: $0.date) == twoDaysAgoStart }
        let yesterdaySummary  = reportedSummaries.first { calendar.startOfDay(for: $0.date) == yesterdayStart }
        let todaySummary      = reportedSummaries.first { calendar.startOfDay(for: $0.date) == todayStart }

        XCTAssertNotNil(twoDaysAgoSummary, "Expected a summary for 2 days ago")
        XCTAssertNotNil(yesterdaySummary,  "Expected a summary for yesterday")
        XCTAssertNotNil(todaySummary,      "Expected a summary for today")

        // Each day should carry its own step count, not have them all collapsed under one date
        XCTAssertEqual(twoDaysAgoSummary?.stepCount, expectedStepCount,
                       "Two-days-ago summary should have its step count correctly attributed")
        XCTAssertEqual(yesterdaySummary?.stepCount, expectedStepCount,
                       "Yesterday's summary should have its step count correctly attributed")
        XCTAssertEqual(todaySummary?.stepCount, expectedStepCount,
                       "Today's summary should have its step count correctly attributed")
    }

    /// Verifies that the last-update timestamp is persisted after a fully successful sync.
    ///
    /// Bug: getAllDailySumsSinceLastUpdate called completion(hasFailure, results) instead of
    /// completion(!hasFailure, results). When all HealthKit queries succeeded (hasFailure=false),
    /// the caller received success=false → containsFailures=true → lastActivityDataUpdateKey was
    /// never written → the query window kept expanding on every subsequent sync.
    func test_successfulSync_savesLastUpdateTimestamp() {
        let calendar = Calendar.current

        // Set a known start point so the query window is short
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        userDefaults.set(yesterday.timeIntervalSince1970, forKey: HealthKitManager.lastActivityDataUpdateKey)

        healthStoreWrapper.return_statisticsQuery_statistics = [
            HKQuantityType(.stepCount): StatisticDTO(sumValue: 3_000),
            HKQuantityType(.distanceWalkingRunning): StatisticDTO(sumValue: 2_000),
            HKQuantityType(.flightsClimbed): StatisticDTO(sumValue: 5),
        ]

        let todayStart = calendar.startOfDay(for: Date())
        healthStoreWrapper.return_activitySummaryQuery_activitySummaries = [
            ActivitySummaryDTO(date: todayStart,
                               activeEnergyBurned: 200, activeEnergyBurnedGoal: 500,
                               appleExerciseTime: 10, appleExerciseTimeGoal: 30,
                               appleStandHours: 5, appleStandHoursGoal: 12)
        ]

        healthKitManager.setupObserverQueries()

        let completionExpectation = expectation(description: "Update handler completion should be called")
        healthStoreWrapper.param_updateHandler!(
            healthStoreWrapper.return_observerQuery!,
            Set([HKQuantityType(.stepCount)]),
            { completionExpectation.fulfill() },
            nil
        )

        waitForExpectations(timeout: 10)

        let savedTimestamp = userDefaults.double(forKey: HealthKitManager.lastActivityDataUpdateKey)
        XCTAssertGreaterThan(savedTimestamp, yesterday.timeIntervalSince1970,
                             "lastActivityDataUpdateKey should be updated after a successful sync; it was stuck at the old value, meaning containsFailures was wrongly true")
    }

    /// Verifies that a stale last-update date older than 30 days is clamped to 30 days ago.
    ///
    /// Bug: thirtyDaysAgo was calculated relative to the stored date (not today), so
    /// `thirtyDaysAgo > date` was always false. Users with a stored date from months ago
    /// would have their query window expand to cover that entire period, making the sync
    /// time out the 60-second background-task budget before any data could be uploaded.
    func test_staleLastUpdateTimestamp_isCappedToThirtyDays() {
        let calendar = Calendar.current

        // Set the last update to 90 days ago (well beyond the 30-day cap)
        let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: Date())!
        userDefaults.set(ninetyDaysAgo.timeIntervalSince1970, forKey: HealthKitManager.lastActivityDataUpdateKey)

        healthStoreWrapper.return_statisticsQuery_statistics = [
            HKQuantityType(.stepCount): StatisticDTO(sumValue: 500),
            HKQuantityType(.distanceWalkingRunning): StatisticDTO(sumValue: 300),
            HKQuantityType(.flightsClimbed): StatisticDTO(sumValue: 2),
        ]

        let todayStart = calendar.startOfDay(for: Date())
        healthStoreWrapper.return_activitySummaryQuery_activitySummaries = [
            ActivitySummaryDTO(date: todayStart,
                               activeEnergyBurned: 100, activeEnergyBurnedGoal: 500,
                               appleExerciseTime: 5, appleExerciseTimeGoal: 30,
                               appleStandHours: 3, appleStandHoursGoal: 12)
        ]

        healthKitManager.setupObserverQueries()

        let completionExpectation = expectation(description: "Update handler completion should be called")
        healthStoreWrapper.param_updateHandler!(
            healthStoreWrapper.return_observerQuery!,
            Set([HKQuantityType(.stepCount)]),
            { completionExpectation.fulfill() },
            nil
        )

        waitForExpectations(timeout: 10)

        // With 3 statistics types (step, distance, flights) and at most 31 days (30-day cap + today),
        // the maximum expected call count is 31 × 3 = 93.
        // Without the fix, a 90-day stale timestamp would produce 90 × 3 = 270 calls.
        let callCount = healthStoreWrapper.executeStatisticsQueryCallCount
        XCTAssertLessThanOrEqual(callCount, 93,
                                 "With a 90-day stale timestamp the 30-day cap should limit statistics queries to ≤93 (31 days × 3 types), got \(callCount)")
        XCTAssertGreaterThan(callCount, 0, "Should have executed at least one statistics query")
    }

    /// Regression test for a closure capture bug in getAllDailySumsSinceLastUpdate.
    ///
    /// The loop variable `date` was captured by reference in the async callback closure.
    /// By the time callbacks fired, `date` had already advanced past the loop — causing all
    /// quantity results (steps, distance, etc.) to be keyed under tomorrow's date instead of
    /// the day they were actually queried for.
    func test_getAllDailySumsSinceLastUpdate_attributesStepCountToCorrectDate() {
        let calendar = Calendar.current

        // Set last update to yesterday so the loop covers exactly two days: yesterday + today.
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        userDefaults.set(yesterday.timeIntervalSince1970, forKey: HealthKitManager.lastActivityDataUpdateKey)

        // Return a known step count for all statistics queries
        let expectedStepCount: UInt = 7_500
        healthStoreWrapper.return_statisticsQuery_statistics = [
            HKQuantityType(.stepCount): StatisticDTO(sumValue: expectedStepCount)
        ]

        // Return a matching activity summary for today
        let todayActivitySummary = ActivitySummaryDTO(date: Date(),
                                                      activeEnergyBurned: 300,
                                                      activeEnergyBurnedGoal: 500,
                                                      appleExerciseTime: 20,
                                                      appleExerciseTimeGoal: 30,
                                                      appleStandHours: 8,
                                                      appleStandHoursGoal: 12)
        healthStoreWrapper.return_activitySummaryQuery_activitySummaries = [todayActivitySummary]

        healthKitManager.setupObserverQueries()
        XCTAssertNotNil(healthStoreWrapper.param_updateHandler)

        let completionExpectation = expectation(description: "Observer update handler should call its completion block")
        healthStoreWrapper.param_updateHandler!(
            healthStoreWrapper.return_observerQuery!,
            Set([HKQuantityType(.stepCount)]),
            { completionExpectation.fulfill() },
            nil
        )

        // Allow enough time for all async HealthKit callbacks to settle
        waitForExpectations(timeout: 10)

        guard let reportedSummaries = activityDataService.param_reportActivitySummaries_activitySummaries else {
            XCTFail("No activity summaries were reported to the backend")
            return
        }

        // No summary should carry a future date — that would indicate the closure capture bug
        // where `date` was read after the loop had already advanced it to tomorrow.
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        let futureSummaries = reportedSummaries.filter { calendar.startOfDay(for: $0.date) >= tomorrow }
        XCTAssertTrue(
            futureSummaries.isEmpty,
            "Activity summaries should not be dated in the future; found dates: \(futureSummaries.map { $0.date })"
        )

        // Today's summary should carry the step count that was reported by HealthKit
        let todayStart = calendar.startOfDay(for: Date())
        let todaySummary = reportedSummaries.first { calendar.startOfDay(for: $0.date) == todayStart }
        XCTAssertNotNil(todaySummary, "Expected a reported activity summary for today")
        XCTAssertEqual(todaySummary?.stepCount, expectedStepCount,
                       "Step count should be attributed to today, not a future date")
    }
}
