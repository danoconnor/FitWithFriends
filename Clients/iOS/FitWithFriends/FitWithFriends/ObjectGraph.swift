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
    let httpConnector: HttpConnector
    let keychainUtilities: KeychainUtilities
    let serviceCommunicator: ServiceCommunicator
    let tokenManager: TokenManager

    init() {
        httpConnector = HttpConnector()
        keychainUtilities = KeychainUtilities()

        tokenManager = TokenManager(keychainUtilities: keychainUtilities)

        serviceCommunicator = ServiceCommunicator(httpConnector: httpConnector,
                                                  tokenManager: tokenManager)

        authenticationManager = AuthenticationManager(serviceCommunicator: serviceCommunicator,
                                                      tokenManager: tokenManager)
    }
}
