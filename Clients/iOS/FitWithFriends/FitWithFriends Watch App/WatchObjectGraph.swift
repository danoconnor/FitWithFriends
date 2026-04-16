//
//  WatchObjectGraph.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import Combine
import Foundation

/// Slim dependency container for the Watch app. The Watch only reads data; it does not
/// initiate sign-in or write activity. HealthKit, Apple sign-in, push, and subscriptions
/// intentionally do not appear here.
class WatchObjectGraph: ObservableObject {
    let keychainUtilities: IKeychainUtilities
    let httpConnector: IHttpConnector
    let serverEnvironmentManager: IServerEnvironmentManager
    let tokenManager: ITokenManager
    let authenticationManager: WatchAuthenticationManager
    let authenticationService: IAuthenticationService
    let competitionService: ICompetitionService
    let competitionManager: CompetitionManager

    init() {
        let keychainUtilities = KeychainUtilities()
        let httpConnector = HttpConnector()
        let serverEnvironmentManager = ServerEnvironmentManager(userDefaults: UserDefaults.standard)
        let tokenManager = TokenManager(keychainUtilities: keychainUtilities)
        let authenticationService = AuthenticationService(httpConnector: httpConnector,
                                                          serverEnvironmentManager: serverEnvironmentManager,
                                                          tokenManager: tokenManager)
        let authenticationManager = WatchAuthenticationManager(tokenManager: tokenManager,
                                                               authenticationService: authenticationService)
        let competitionService = CompetitionService(httpConnector: httpConnector,
                                                    serverEnvironmentManager: serverEnvironmentManager,
                                                    tokenManager: tokenManager)
        let competitionManager = CompetitionManager(authenticationManager: authenticationManager,
                                                    competitionService: competitionService)

        self.keychainUtilities = keychainUtilities
        self.httpConnector = httpConnector
        self.serverEnvironmentManager = serverEnvironmentManager
        self.tokenManager = tokenManager
        self.authenticationService = authenticationService
        self.authenticationManager = authenticationManager
        self.competitionService = competitionService
        self.competitionManager = competitionManager

        // Kick off the initial login-state check. This flows through WatchAuthenticationManager
        // which will read the token from the shared Keychain and publish .loggedIn if found,
        // which in turn triggers CompetitionManager.refreshCompetitionOverviews() through its
        // existing login-state subscription.
        authenticationManager.evaluateInitialLoginState()
    }

    /// Test-only initializer that lets callers inject pre-built dependencies. Used by unit tests
    /// to exercise WatchObjectGraph wiring without touching the real keychain or network.
    init(keychainUtilities: IKeychainUtilities,
         httpConnector: IHttpConnector,
         serverEnvironmentManager: IServerEnvironmentManager,
         tokenManager: ITokenManager,
         authenticationService: IAuthenticationService,
         authenticationManager: WatchAuthenticationManager,
         competitionService: ICompetitionService,
         competitionManager: CompetitionManager) {
        self.keychainUtilities = keychainUtilities
        self.httpConnector = httpConnector
        self.serverEnvironmentManager = serverEnvironmentManager
        self.tokenManager = tokenManager
        self.authenticationService = authenticationService
        self.authenticationManager = authenticationManager
        self.competitionService = competitionService
        self.competitionManager = competitionManager
    }
}
