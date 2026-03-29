//
//  PushNotificationManager.swift
//  FitWithFriends
//

import Foundation
import UIKit
import UserNotifications

public class PushNotificationManager: IPushNotificationManager {
    private static let appInstallIdKey = "appInstallId"

    private let pushNotificationService: IPushNotificationService
    private let userDefaults: UserDefaults

    private var appInstallId: String {
        if let existingId = userDefaults.string(forKey: Self.appInstallIdKey) {
            return existingId
        }
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: Self.appInstallIdKey)
        return newId
    }

    public init(pushNotificationService: IPushNotificationService, userDefaults: UserDefaults) {
        self.pushNotificationService = pushNotificationService
        self.userDefaults = userDefaults
    }

    public func requestPushPermissionsAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Logger.traceError(message: "Error requesting push notification permission", error: error)
                return
            }

            guard granted else {
                Logger.traceInfo(message: "Push notification permission denied by user")
                return
            }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    public func handleDeviceToken(_ tokenData: Data) {
        let pushToken = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        let appInstallId = self.appInstallId

        Task.detached {
            do {
                try await self.pushNotificationService.registerPushToken(pushToken, appInstallId: appInstallId)
                Logger.traceInfo(message: "Successfully registered push token with server")
            } catch {
                Logger.traceError(message: "Failed to register push token with server", error: error)
            }
        }
    }
}
