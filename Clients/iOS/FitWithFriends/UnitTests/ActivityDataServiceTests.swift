//
//  ActivityDataServiceTests.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/10/24.
//

import Foundation
import Fit_with_Friends

import XCTest

final class ActivityDataServiceTests: XCTestCase {
    private var activityDataService: ActivityDataService!

    private var httpConnector: MockHttpConnector!
    private var tokenManager: MockTokenManager!

    override func setUp() {
        httpConnector = MockHttpConnector()
        tokenManager = MockTokenManager()

        activityDataService = ActivityDataService(httpConnector: httpConnector, tokenManager: tokenManager)

        // Default httpConnector to return an empty response
        httpConnector.return_data = EmptyResponse()
    }

    func test_reportWorkouts_success() {
        let workoutDTOs = [
            WorkoutSampleDTO(startDate: Date(), duration: 30 * 60, caloriesBurned: 100, activityType: .traditionalStrengthTraining, distance: nil, unit: .none),
            WorkoutSampleDTO(startDate: Date().addingTimeInterval(-60 * 60 * 24), duration: 45 * 60, caloriesBurned: 567, activityType: .swimming, distance: 5000, unit: .meter)
        ]
        let workouts = workoutDTOs.map { Workout(workout: $0) }

        let expectation = expectation(description: "Reported workouts")
        activityDataService.reportWorkouts(workouts) { error in
            XCTAssertNil(error, "Should not have an error")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}
