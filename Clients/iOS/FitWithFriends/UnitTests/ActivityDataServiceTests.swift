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
    }
}
