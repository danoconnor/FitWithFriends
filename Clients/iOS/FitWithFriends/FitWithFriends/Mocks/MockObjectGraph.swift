//
//  MockObjectGraph.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockObjectGraph: IObjectGraph {
    var activityDataService: IActivityDataService
    var appleIDProvider: IASAuthorizationAppleIDProvider
    var appProtocolHandler: IAppProtocolHandler
    var authenticationManager: IAuthenticationManager
    var authenticationService: IAuthenticationService
    var competitionManager: ICompetitionManager
    var competitionService: ICompetitionService
    var emailUtility: IEmailUtility
    var healthKitManager: IHealthKitManager
    var httpConnector: IHttpConnector
    var keychainUtilities: IKeychainUtilities
    var serverEnvironmentManager: ServerEnvironmentManager
    var shakeGestureHandler: IShakeGestureHandler
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
        appleIDProvider = MockASAuthorizationAppleIDProvider()

        serverEnvironmentManager = ServerEnvironmentManager(userDefaults: userDefaults)
    }
}
