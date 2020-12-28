//
//  PushNotificationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/26/20.
//

import Combine
import Foundation
import UIKit
import UserNotifications

class PushNotificationManager {
    private let authenticationManager: AuthenticationManager
    private let pushNotificationService: PushNotificationService
    private let userDefaults: UserDefaults

    private let tokenCacheKey = "PushToken"

    private var loginStateCancellable: AnyCancellable?

    init(authenticationManager: AuthenticationManager,
         pushNotificationService: PushNotificationService,
         userDefaults: UserDefaults) {
        self.authenticationManager = authenticationManager
        self.pushNotificationService = pushNotificationService
        self.userDefaults = userDefaults

        loginStateCancellable =  authenticationManager.$loginState.sink { [weak self] state in
            if state == .loggedIn {
                // When the user logs in, we want to request an APNS token from the system
                // to get the latest APNS token (it might change)
                self?.requestPushToken()
            } else if state == .notLoggedIn {
                // TODO: unregsiter push notifications on logout
            }
        }
    }

    var shouldPromptUser: Bool {
        let group = DispatchGroup()

        var shouldPrompt = false
        group.enter()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                shouldPrompt = true
            default:
                shouldPrompt = false
            }

            group.leave()
        }

        // Wait up to 1 second for the system to return the notification settings
        _ = group.wait(timeout: .now() + 1)
        return shouldPrompt
    }

    func promptForNotificationPermission(completion: @escaping () -> Void) {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { [weak self] granted, error in
            if let error = error {
                Logger.traceError(message: "Failed to request push notification authorization", error: error)
            }

            Logger.traceInfo(message: "Received authorization for push notifications: \(granted)")
            self?.requestPushToken()

            completion()
        }
    }

    func requestPushToken() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func registerPushTokenIfNecessary(_ pushToken: Data) {
        // Check to see if the token has changed since the last time
        // If it has, send the new token to the service
        let tokenString = convertPushTokenToString(data: pushToken)
        let tokenPart = tokenString.suffix(10)

        if let cachedTokenPart = userDefaults.string(forKey: tokenCacheKey),
            tokenPart == cachedTokenPart {
            Logger.traceInfo(message: "Token has not changed, no need to register token again")
            return
        }

        pushNotificationService.registerApnsToken(token: tokenString) { [weak self] error in
            if let error = error {
                Logger.traceError(message: "Failed to register APNS token with service", error: error)
                return
            }

            guard let self = self else { return }

            self.userDefaults.set(tokenPart, forKey: self.tokenCacheKey)
            Logger.traceInfo(message: "Successfully registered APNS token with service")
        }
    }

    private func convertPushTokenToString(data: Data) -> String {
        var token: String = ""
        for i in 0 ..< data.count {
            token += String(format: "%02.2hhx", data[i] as CVarArg)
        }

        return token
    }
}
