//
//  IObjectGraph.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

protocol IObjectGraph {
    var activityDataService: IActivityDataService { get }
    var appProtocolHandler: AppProtocolHandler { get }
    var authenticationManager: AuthenticationManager { get }
    var authenticationService: IAuthenticationService { get }
    var competitionManager: CompetitionManager { get }
    var competitionService: ICompetitionService { get }
    var emailUtility: EmailUtility { get }
    var healthKitManager: IHealthKitManager { get }
    var httpConnector: IHttpConnector { get }
    var keychainUtilities: KeychainUtilities { get }
    var shakeGestureHandler: ShakeGestureHandler { get }
    var tokenManager: TokenManager { get }
    var userDefaults: UserDefaults { get }
    var userService: IUserService { get }
}
