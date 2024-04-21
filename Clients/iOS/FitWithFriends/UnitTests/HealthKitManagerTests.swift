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
        waitForExpectations(timeout: 1)

        // Validate that we should still attempt a prompt on next launch
        XCTAssertTrue(healthKitManager.shouldPromptUser, "Should still prompt user because we did not prompt successfully")
    }

    func test_requestHealthKitPermission_success() {
        healthStoreWrapper.return_authorizationSuccess = true

        let expectation = expectation(description: "completion called")
        healthKitManager.requestHealthKitPermission {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)

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
        XCTAssertEqual(healthStoreWrapper.requestedBackgroundTypes.count, 7)
        XCTAssertTrue(healthStoreWrapper.requestedBackgroundTypes.contains(where: { $0.type == .workoutType() && $0.frequency == .immediate }))
        XCTAssertTrue(healthStoreWrapper.requestedBackgroundTypes.contains(where: { $0.type == HKQuantityType(.activeEnergyBurned) && $0.frequency == .hourly }))
        XCTAssertTrue(healthStoreWrapper.requestedBackgroundTypes.contains(where: { $0.type == HKQuantityType(.appleExerciseTime) && $0.frequency == .hourly }))
        XCTAssertTrue(healthStoreWrapper.requestedBackgroundTypes.contains(where: { $0.type == HKQuantityType(.appleStandTime) && $0.frequency == .hourly }))
        XCTAssertTrue(healthStoreWrapper.requestedBackgroundTypes.contains(where: { $0.type == HKQuantityType(.stepCount) && $0.frequency == .hourly }))
        XCTAssertTrue(healthStoreWrapper.requestedBackgroundTypes.contains(where: { $0.type == HKQuantityType(.distanceWalkingRunning) && $0.frequency == .hourly }))
        XCTAssertTrue(healthStoreWrapper.requestedBackgroundTypes.contains(where: { $0.type == HKQuantityType(.flightsClimbed) && $0.frequency == .hourly }))
    }

    func test_setupObserverQueries_validateObserverQueries() {
        healthKitManager.setupObserverQueries()

        // Validate that we requested observer updates for all the types we care about
        XCTAssertNotNil(healthStoreWrapper.param_queryDescriptors)
        XCTAssertNotNil(healthStoreWrapper.param_updateHandler)

        XCTAssertTrue(healthStoreWrapper.param_queryDescriptors!.contains(where: { $0.sampleType == .workoutType() }))
        XCTAssertTrue(healthStoreWrapper.param_queryDescriptors!.contains(where: { $0.sampleType == HKQuantityType(.activeEnergyBurned) }))
        XCTAssertTrue(healthStoreWrapper.param_queryDescriptors!.contains(where: { $0.sampleType == HKQuantityType(.appleExerciseTime) }))
        XCTAssertTrue(healthStoreWrapper.param_queryDescriptors!.contains(where: { $0.sampleType == HKQuantityType(.appleStandTime) }))
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
}
