//
//  MockObjectGraph.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockObjectGraph: IObjectGraph {
    var activityDataService: ActivityDataService
    var authenticationManager: AuthenticationManager
    var authenticationService: AuthenticationService
    var competitionManager: CompetitionManager
    var competitionService: CompetitionService
    var emailUtility: EmailUtility
    var healthKitManager: HealthKitManager
    var httpConnector: HttpConnector
    var keychainUtilities: KeychainUtilities
    var shakeGestureHandler: ShakeGestureHandler
    var tokenManager: TokenManager
    var userDefaults: UserDefaults
    var userService: UserService

    init() {
        activityDataService = MockActivityDataService()
        authenticationManager = MockAuthenticationManager()
        authenticationService = MockAuthenticationService()
        competitionManager = MockCompetitionManager()
        competitionService = MockCompetitionService()
        emailUtility = MockEmailUtility()
        healthKitManager = MockHealthKitManager()
        httpConnector = MockHttpConnector()
        keychainUtilities = MockKeychainUtilities()
        shakeGestureHandler = MockShakeGestureHandler()
        tokenManager = MockTokenManager()
        userDefaults = UserDefaults.standard
        userService = MockUserService()
    }
}
