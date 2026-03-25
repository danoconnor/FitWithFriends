//
//  IObjectGraph.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

protocol IObjectGraph {
    var activityDataService: IActivityDataService { get }
    var appProtocolHandler: IAppProtocolHandler { get }
    var authenticationManager: IAuthenticationManager { get }
    var authenticationService: IAuthenticationService { get }
    var competitionManager: ICompetitionManager { get }
    var competitionService: ICompetitionService { get }
    var emailUtility: IEmailUtility { get }
    var healthKitManager: IHealthKitManager { get }
    var httpConnector: IHttpConnector { get }
    var keychainUtilities: IKeychainUtilities { get }
    var serverEnvironmentManager: ServerEnvironmentManager { get }
    var shakeGestureHandler: IShakeGestureHandler { get }
    var tokenManager: ITokenManager { get }
    var userDefaults: UserDefaults { get }
    var userService: IUserService { get }
    var appleIDProvider: IASAuthorizationAppleIDProvider { get }
}
