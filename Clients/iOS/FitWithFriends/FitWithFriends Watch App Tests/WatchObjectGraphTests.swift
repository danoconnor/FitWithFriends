//
//  WatchObjectGraphTests.swift
//  FitWithFriends Watch App Tests
//
//  Created by Dan O'Connor on 4/14/26.
//

import XCTest
import Combine
@testable import FitWithFriends_Watch_App

final class WatchObjectGraphTests: XCTestCase {
    func test_productionInit_wiresConcreteDependencies() {
        let objectGraph = WatchObjectGraph()

        XCTAssertNotNil(objectGraph.keychainUtilities)
        XCTAssertNotNil(objectGraph.httpConnector)
        XCTAssertNotNil(objectGraph.serverEnvironmentManager)
        XCTAssertNotNil(objectGraph.tokenManager)
        XCTAssertNotNil(objectGraph.authenticationService)
        XCTAssertNotNil(objectGraph.authenticationManager)
        XCTAssertNotNil(objectGraph.competitionService)
        XCTAssertNotNil(objectGraph.competitionManager)
    }

    func test_watchAuthenticationManager_withoutCachedToken_publishesSignedOut() {
        let keychain = MockKeychainUtilities()
        let tokenManager = TokenManager(keychainUtilities: keychain)
        let mockService = MockAuthenticationService()
        let authManager = WatchAuthenticationManager(
            tokenManager: tokenManager,
            authenticationService: mockService
        )

        authManager.evaluateInitialLoginState()

        if case .notLoggedIn = authManager.loginState {
            // pass
        } else {
            XCTFail("Expected .notLoggedIn for a watch with no cached token, got \(authManager.loginState)")
        }
        XCTAssertNil(authManager.loggedInUserId)
    }

    func test_watchAuthenticationManager_logout_clearsTokensAndUserId() {
        let keychain = MockKeychainUtilities()
        let tokenManager = TokenManager(keychainUtilities: keychain)
        let mockService = MockAuthenticationService()
        let authManager = WatchAuthenticationManager(
            tokenManager: tokenManager,
            authenticationService: mockService
        )
        authManager.loggedInUserId = "someone"
        authManager.loginState = .loggedIn

        authManager.logout()

        if case .notLoggedIn = authManager.loginState {
            // pass
        } else {
            XCTFail("Expected .notLoggedIn after logout")
        }
        XCTAssertNil(authManager.loggedInUserId)
    }

    // beginLogin is not available on watchOS — the protocol method is guarded with #if !os(watchOS)
}
