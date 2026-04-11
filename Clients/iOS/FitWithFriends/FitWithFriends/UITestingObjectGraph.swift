//
//  UITestingObjectGraph.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/27/26.
//

#if DEBUG

import Foundation

/// Object graph used for UI testing.
/// Uses real HTTP networking against the Docker backend (localhost:3000),
/// but mocks HealthKit, Apple authentication, and keychain.
class UITestingObjectGraph: IObjectGraph {
    let activityDataService: IActivityDataService
    let appleIDProvider: IASAuthorizationAppleIDProvider
    let appProtocolHandler: IAppProtocolHandler
    let authenticationManager: IAuthenticationManager
    let authenticationService: IAuthenticationService
    let competitionManager: ICompetitionManager
    let competitionService: ICompetitionService
    let emailUtility: IEmailUtility
    let healthKitManager: IHealthKitManager
    let httpConnector: IHttpConnector
    let keychainUtilities: IKeychainUtilities
    let serverEnvironmentManager: IServerEnvironmentManager
    let shakeGestureHandler: IShakeGestureHandler
    let tokenManager: ITokenManager
    let userDefaults: UserDefaults
    let userService: IUserService
    let pushNotificationManager: IPushNotificationManager
    let pushNotificationService: IPushNotificationService
    let subscriptionManager: ISubscriptionManager
    let subscriptionService: ISubscriptionService
    let appMetadataService: IAppMetadataService
    let appVersionManager: IAppVersionManager

    init() {
        let env = ProcessInfo.processInfo.environment

        // Mocks that don't need real device capabilities
        appleIDProvider = MockASAuthorizationAppleIDProvider()
        appProtocolHandler = MockAppProtocolHandler()
        emailUtility = MockEmailUtility()
        keychainUtilities = MockKeychainUtilities()
        userDefaults = UserDefaults.standard

        let shakeHandler = MockShakeGestureHandler()
        shakeGestureHandler = shakeHandler

        // Configure server environment to point at Docker backend
        let mockServerEnv = MockServerEnvironmentManager()
        mockServerEnv.baseUrl = "http://localhost:3000"
        mockServerEnv.clientId = "6A773C32-5EB3-41C9-8036-B991B51F14F7"
        mockServerEnv.clientSecret = "11279ED4-2687-408D-9AE7-22AB3CA41219"
        mockServerEnv.isLocalTesting = true
        serverEnvironmentManager = mockServerEnv

        // Reset the first-launch flag in the persistent store so the welcome sheet
        // appears and can be properly dismissed in tests that exercise it.
        // We can't use a launch arg for this because launch args create a volatile
        // UserDefaults domain that overrides any programmatic writes during the session.
        if env["FWF_UI_TEST_SHOW_FIRST_LAUNCH"] == "1" {
            UserDefaults.standard.removeObject(forKey: "HasShownFirstLaunch")
        }

        // Configure token manager with injected tokens from test runner
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
        tokenManager = mockTokenManager

        // Configure mock HealthKit with sample activity data for screenshots
        let mockHealthKit = MockHealthKitManager()
        let sampleActivity = ActivitySummary(
            activitySummary: ActivitySummaryDTO(
                date: Date(),
                activeEnergyBurned: 420,
                activeEnergyBurnedGoal: 500,
                appleExerciseTime: 35,
                appleExerciseTimeGoal: 30,
                appleStandHours: 9,
                appleStandHoursGoal: 12
            )
        )
        mockHealthKit.return_getCurrentActivitySummary = sampleActivity
        healthKitManager = mockHealthKit

        // Real HTTP connector for backend communication
        httpConnector = HttpConnector()

        // Real services wired to Docker backend
        activityDataService = ActivityDataService(httpConnector: httpConnector, serverEnvironmentManager: serverEnvironmentManager, tokenManager: tokenManager)
        authenticationService = AuthenticationService(httpConnector: httpConnector, serverEnvironmentManager: serverEnvironmentManager, tokenManager: tokenManager)
        competitionService = CompetitionService(httpConnector: httpConnector, serverEnvironmentManager: serverEnvironmentManager, tokenManager: tokenManager)
        userService = UserService(httpConnector: httpConnector, serverEnvironmentManager: serverEnvironmentManager, tokenManager: tokenManager)
        pushNotificationService = PushNotificationService(httpConnector: httpConnector, serverEnvironmentManager: serverEnvironmentManager, tokenManager: tokenManager)

        // Use mock push notification manager in UI tests - we don't want to prompt for permission
        pushNotificationManager = MockPushNotificationManager()

        // Use real subscription service but mock manager in UI tests - StoreKit is not available in test environment
        subscriptionService = SubscriptionService(httpConnector: httpConnector, serverEnvironmentManager: serverEnvironmentManager, tokenManager: tokenManager)
        let mockSubscriptionManager = MockSubscriptionManager()
        mockSubscriptionManager.return_isUserPro = env["FWF_UI_TEST_IS_PRO"] == "1"
        subscriptionManager = mockSubscriptionManager

        // Use real app metadata service but mock version manager in UI tests
        appMetadataService = AppMetadataService(httpConnector: httpConnector, serverEnvironmentManager: serverEnvironmentManager)
        appVersionManager = MockAppVersionManager()

        // Wire up authentication with mock Apple auth (always valid)
        let mockAppleAuth = MockAppleAuthenticationManager()
        mockAppleAuth.return_isAppleAccountValid = true

        // Configure login outcome for UI tests that exercise the sign-in flow
        if let outcome = env["FWF_UI_TEST_LOGIN_OUTCOME"] {
            switch outcome {
            case "success":
                mockAppleAuth.return_loginOutcome = .success
                // Re-use the same injected token so the app lands on the home screen
                mockAppleAuth.return_loginToken = mockTokenManager.return_token
            case "failure":
                mockAppleAuth.return_loginOutcome = .failure
            default:
                break
            }
        }

        let authManager = AuthenticationManager(appleAuthenticationManager: mockAppleAuth,
                                                 authenticationService: authenticationService,
                                                 tokenManager: tokenManager)
        authenticationManager = authManager
        mockAppleAuth.authenticationDelegate = authManager

        let compManager = CompetitionManager(authenticationManager: authenticationManager,
                                              competitionService: competitionService)
        competitionManager = compManager
    }
}

#endif
