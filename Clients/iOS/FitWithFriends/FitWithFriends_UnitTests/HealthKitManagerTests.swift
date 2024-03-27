//
//  HealthKitManagerTests.swift
//  FitWithFriends_UnitTests
//
//  Created by Dan O'Connor on 3/26/24.
//

import Foundation
import Fit_with_Friends

import XCTest

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

    func testExample() throws {

    }
}
