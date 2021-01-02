//
//  ObjectGraph.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

class ObjectGraph {
    static let sharedInstance = ObjectGraph()

    let activityDataService: ActivityDataService
    let authenticationManager: AuthenticationManager
    let authenticationService: AuthenticationService
    let competitionManager: CompetitionManager
    let competitionService: CompetitionService
    let healthKitManager: HealthKitManager
    let httpConnector: HttpConnector
    let keychainUtilities: KeychainUtilities
    let pushNotificationManager: PushNotificationManager
    let pushNotificationService: PushNotificationService
    let tokenManager: TokenManager
    let userDefaults: UserDefaults
    let userService: UserService

    init() {
        httpConnector = HttpConnector()
        keychainUtilities = KeychainUtilities()
        userDefaults = UserDefaults.standard

        tokenManager = TokenManager(keychainUtilities: keychainUtilities)

        activityDataService = ActivityDataService(httpConnector: httpConnector, tokenManager: tokenManager)
        authenticationService = AuthenticationService(httpConnector: httpConnector, tokenManager: tokenManager)
        competitionService = CompetitionService(httpConnector: httpConnector, tokenManager: tokenManager)
        pushNotificationService = PushNotificationService(httpConnector: httpConnector, tokenManager: tokenManager)
        userService = UserService(httpConnector: httpConnector, tokenManager: tokenManager)

        authenticationManager = AuthenticationManager(authenticationService: authenticationService,
                                                      tokenManager: tokenManager)

        healthKitManager = HealthKitManager(activityDataService: activityDataService,
                                            authenticationManager: authenticationManager,
                                            userDefaults: userDefaults)

        pushNotificationManager = PushNotificationManager(authenticationManager: authenticationManager,
                                                          pushNotificationService: pushNotificationService,
                                                          userDefaults: userDefaults)

        competitionManager = CompetitionManager(authenticationManager: authenticationManager,
                                                competitionService: competitionService)
    }
}
