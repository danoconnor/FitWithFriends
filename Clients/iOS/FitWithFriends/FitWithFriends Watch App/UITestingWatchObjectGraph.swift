//
//  UITestingWatchObjectGraph.swift
//  FitWithFriends Watch App
//
//  UI testing object graph for the Watch app. Uses real HTTP networking against
//  the Docker backend (localhost:3000), but injects the access token from
//  environment variables and skips WatchConnectivity.
//

#if DEBUG

import Foundation

class UITestingWatchObjectGraph: WatchObjectGraph {
    override init() {
        let env = ProcessInfo.processInfo.environment

        let keychainUtilities = MockKeychainUtilities()
        let httpConnector = HttpConnector()

        let mockServerEnv = MockServerEnvironmentManager()
        mockServerEnv.baseUrl = "http://localhost:3000"
        mockServerEnv.clientId = "6A773C32-5EB3-41C9-8036-B991B51F14F7"
        mockServerEnv.clientSecret = "11279ED4-2687-408D-9AE7-22AB3CA41219"
        mockServerEnv.isLocalTesting = true

        let mockTokenManager = MockTokenManager()
        if let accessToken = env["FWF_UI_TEST_ACCESS_TOKEN"],
           let expiryString = env["FWF_UI_TEST_ACCESS_TOKEN_EXPIRY"],
           let refreshToken = env["FWF_UI_TEST_REFRESH_TOKEN"],
           let userId = env["FWF_UI_TEST_USER_ID"] {
            let expiry = ISO8601DateFormatter().date(from: expiryString) ?? Date(timeIntervalSinceNow: 3600)
            mockTokenManager.return_token = Token(accessToken: accessToken,
                                                   accessTokenExpiry: expiry,
                                                   refreshToken: refreshToken,
                                                   userId: userId)
        } else {
            mockTokenManager.return_token = nil
        }

        let authenticationService = AuthenticationService(httpConnector: httpConnector,
                                                          serverEnvironmentManager: mockServerEnv,
                                                          tokenManager: mockTokenManager)
        let authenticationManager = WatchAuthenticationManager(tokenManager: mockTokenManager,
                                                               authenticationService: authenticationService)
        let competitionService = CompetitionService(httpConnector: httpConnector,
                                                    serverEnvironmentManager: mockServerEnv,
                                                    tokenManager: mockTokenManager)
        let competitionManager = CompetitionManager(authenticationManager: authenticationManager,
                                                    competitionService: competitionService)

        super.init(keychainUtilities: keychainUtilities,
                   httpConnector: httpConnector,
                   serverEnvironmentManager: mockServerEnv,
                   tokenManager: mockTokenManager,
                   authenticationService: authenticationService,
                   authenticationManager: authenticationManager,
                   competitionService: competitionService,
                   competitionManager: competitionManager)

        // Evaluate login state based on injected token (skips WatchConnectivity)
        authenticationManager.evaluateInitialLoginState()
    }
}

#endif
