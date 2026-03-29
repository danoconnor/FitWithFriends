//
//  ObjectGraph.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

class ObjectGraph: IObjectGraph {
    let activityDataService: IActivityDataService
    let appleAuthenticationManager: IAppleAuthenticationManager
    let appleIDProvider: IASAuthorizationAppleIDProvider
    let appProtocolHandler: IAppProtocolHandler
    let authenticationManager: IAuthenticationManager
    let authenticationService: IAuthenticationService
    let competitionManager: ICompetitionManager
    let competitionService: ICompetitionService
    let emailUtility: IEmailUtility
    let healthKitManager: IHealthKitManager
    let healthStoreWrapper: IHealthStoreWrapper
    let httpConnector: IHttpConnector
    let keychainUtilities: IKeychainUtilities
    let serverEnvironmentManager: IServerEnvironmentManager
    let shakeGestureHandler: IShakeGestureHandler
    let tokenManager: ITokenManager
    let userDefaults: UserDefaults
    let userService: IUserService
    let pushNotificationManager: IPushNotificationManager
    let pushNotificationService: IPushNotificationService

    init() {
        appleIDProvider = ASAuthorizationAppleIDProviderWrapper()
        appProtocolHandler = AppProtocolHandler()
        httpConnector = HttpConnector()
        keychainUtilities = KeychainUtilities()
        userDefaults = UserDefaults.standard
        emailUtility = EmailUtility()
        healthStoreWrapper = HealthStoreWrapper()

        serverEnvironmentManager = ServerEnvironmentManager(userDefaults: userDefaults) as IServerEnvironmentManager
        shakeGestureHandler = ShakeGestureHandler(emailUtility: emailUtility)
        tokenManager = TokenManager(keychainUtilities: keychainUtilities)

        activityDataService = ActivityDataService(httpConnector: httpConnector, serverEnvironmentManager: serverEnvironmentManager, tokenManager: tokenManager)
        authenticationService = AuthenticationService(httpConnector: httpConnector, serverEnvironmentManager: serverEnvironmentManager, tokenManager: tokenManager)
        competitionService = CompetitionService(httpConnector: httpConnector, serverEnvironmentManager: serverEnvironmentManager, tokenManager: tokenManager)
        userService = UserService(httpConnector: httpConnector, serverEnvironmentManager: serverEnvironmentManager, tokenManager: tokenManager)
        pushNotificationService = PushNotificationService(httpConnector: httpConnector, serverEnvironmentManager: serverEnvironmentManager, tokenManager: tokenManager)
        pushNotificationManager = PushNotificationManager(pushNotificationService: pushNotificationService, userDefaults: userDefaults)

        appleAuthenticationManager = AppleAuthenticationManager(appleIDProvider: appleIDProvider,
                                                                authenticationService: authenticationService,
                                                                keychainUtilities: keychainUtilities,
                                                                serverEnvironmentManager: serverEnvironmentManager,
                                                                userService: userService)
        let authenticationManager = AuthenticationManager(appleAuthenticationManager: appleAuthenticationManager,
                                                      authenticationService: authenticationService,
                                                      tokenManager: tokenManager)
        self.authenticationManager = authenticationManager
        appleAuthenticationManager.authenticationDelegate = authenticationManager

        let competitionManager = CompetitionManager(authenticationManager: authenticationManager,
                                                competitionService: competitionService)
        self.competitionManager = competitionManager
        healthKitManager = HealthKitManager(activityDataService: activityDataService,
                                            activityUpdateDelegate: competitionManager,
                                            authenticationManager: authenticationManager,
                                            healthStoreWrapper: healthStoreWrapper,
                                            userDefaults: userDefaults)
    }
}
