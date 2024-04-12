//
//  MockObjectGraph.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockObjectGraph: IObjectGraph {
    var activityDataService: IActivityDataService
    var appProtocolHandler: AppProtocolHandler
    var authenticationManager: AuthenticationManager
    var authenticationService: IAuthenticationService
    var competitionManager: CompetitionManager
    var competitionService: ICompetitionService
    var emailUtility: EmailUtility
    var healthKitManager: IHealthKitManager
    var httpConnector: IHttpConnector
    var keychainUtilities: IKeychainUtilities
    var shakeGestureHandler: ShakeGestureHandler
    var tokenManager: ITokenManager
    var userDefaults: UserDefaults
    var userService: IUserService

    init() {
        activityDataService = MockActivityDataService()
        appProtocolHandler = MockAppProtocolHandler()
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
