//
//  ObjectGraph.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

class ObjectGraph {
    static let sharedInstance = ObjectGraph()

    let authenticationManager: AuthenticationManager
    let healthKitManager: HealthKitManager
    let httpConnector: HttpConnector
    let keychainUtilities: KeychainUtilities
    let pushNotificationManager: PushNotificationManager
    let serviceCommunicator: ServiceCommunicator
    let tokenManager: TokenManager
    let userDefaults: UserDefaults

    init() {
        httpConnector = HttpConnector()
        keychainUtilities = KeychainUtilities()
        userDefaults = UserDefaults.standard

        tokenManager = TokenManager(keychainUtilities: keychainUtilities)

        serviceCommunicator = ServiceCommunicator(httpConnector: httpConnector,
                                                  tokenManager: tokenManager)

        authenticationManager = AuthenticationManager(serviceCommunicator: serviceCommunicator,
                                                      tokenManager: tokenManager)

        healthKitManager = HealthKitManager(authenticationManager: authenticationManager,
                                            serviceCommunicator: serviceCommunicator,
                                            userDefaults: userDefaults)

        pushNotificationManager = PushNotificationManager(authenticationManager: authenticationManager,
                                                          serviceCommunicator: serviceCommunicator,
                                                          userDefaults: userDefaults)
    }
}
