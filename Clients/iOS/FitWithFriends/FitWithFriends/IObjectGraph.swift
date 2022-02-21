//
//  IObjectGraph.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

protocol IObjectGraph {
    var activityDataService: ActivityDataService { get }
    var appProtocolHandler: AppProtocolHandler { get }
    var authenticationManager: AuthenticationManager { get }
    var authenticationService: AuthenticationService { get }
    var competitionManager: CompetitionManager { get }
    var competitionService: CompetitionService { get }
    var emailUtility: EmailUtility { get }
    var healthKitManager: HealthKitManager { get }
    var httpConnector: HttpConnector { get }
    var keychainUtilities: KeychainUtilities { get }
    var shakeGestureHandler: ShakeGestureHandler { get }
    var tokenManager: TokenManager { get }
    var userDefaults: UserDefaults { get }
    var userService: UserService { get }
}
