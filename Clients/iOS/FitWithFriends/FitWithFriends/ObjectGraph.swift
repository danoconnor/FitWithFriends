//
//  ObjectGraph.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

class ObjectGraph: IObjectGraph {
    let activityDataService: ActivityDataService
    let appleAuthenticationManager: AppleAuthenticationManager
    let appProtocolHandler: AppProtocolHandler
    let authenticationManager: AuthenticationManager
    let authenticationService: AuthenticationService
    let competitionManager: CompetitionManager
    let competitionService: CompetitionService
    let emailUtility: EmailUtility
    let healthKitManager: HealthKitManager
    let httpConnector: HttpConnector
    let keychainUtilities: KeychainUtilities
    let shakeGestureHandler: ShakeGestureHandler
    let tokenManager: TokenManager
    let userDefaults: UserDefaults
    let userService: UserService

    init() {
        appProtocolHandler = AppProtocolHandler()
        httpConnector = HttpConnector()
        keychainUtilities = KeychainUtilities()
        userDefaults = UserDefaults.standard
        emailUtility = EmailUtility()

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
                                            userDefaults: userDefaults)
    }
}
