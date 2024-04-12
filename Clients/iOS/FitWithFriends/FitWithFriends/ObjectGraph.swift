//
//  ObjectGraph.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

class ObjectGraph: IObjectGraph {
    let activityDataService: IActivityDataService
    let appleAuthenticationManager: AppleAuthenticationManager
    let appProtocolHandler: AppProtocolHandler
    let authenticationManager: AuthenticationManager
    let authenticationService: IAuthenticationService
    let competitionManager: CompetitionManager
    let competitionService: ICompetitionService
    let emailUtility: EmailUtility
    let healthKitManager: IHealthKitManager
    let healthStoreWrapper: IHealthStoreWrapper
    let httpConnector: IHttpConnector
    let keychainUtilities: IKeychainUtilities
    let shakeGestureHandler: ShakeGestureHandler
    let tokenManager: ITokenManager
    let userDefaults: UserDefaults
    let userService: IUserService

    init() {
        appProtocolHandler = AppProtocolHandler()
        httpConnector = HttpConnector()
        keychainUtilities = KeychainUtilities()
        userDefaults = UserDefaults.standard
        emailUtility = EmailUtility()
        healthStoreWrapper = HealthStoreWrapper()

        shakeGestureHandler = ShakeGestureHandler(emailUtility: emailUtility)
        tokenManager = TokenManager(keychainUtilities: keychainUtilities)

        activityDataService = ActivityDataService(httpConnector: httpConnector, tokenManager: tokenManager)
        authenticationService = AuthenticationService(httpConnector: httpConnector, tokenManager: tokenManager)
        competitionService = CompetitionService(httpConnector: httpConnector, tokenManager: tokenManager)
        userService = UserService(httpConnector: httpConnector, tokenManager: tokenManager)

        appleAuthenticationManager = AppleAuthenticationManager(authenticationService: authenticationService,
                                                                keychainUtilities: keychainUtilities,
                                                                userService: userService)
        authenticationManager = AuthenticationManager(appleAuthenticationManager: appleAuthenticationManager,
                                                      authenticationService: authenticationService,
                                                      tokenManager: tokenManager)
        appleAuthenticationManager.authenticationDelegate = authenticationManager

        competitionManager = CompetitionManager(authenticationManager: authenticationManager,
                                                competitionService: competitionService)

        healthKitManager = HealthKitManager(activityDataService: activityDataService,
                                            activityUpdateDelegate: competitionManager,
                                            authenticationManager: authenticationManager,
                                            healthStoreWrapper: healthStoreWrapper,
                                            userDefaults: userDefaults)
    }
}
