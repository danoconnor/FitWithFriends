//
//  IPushNotificationManager.swift
//  FitWithFriends
//

import Foundation

public protocol IPushNotificationManager {
    /// Requests push notification permission from the user and registers with APNs if granted
    func requestPushPermissionsAndRegister()

    /// Called by the app delegate when APNs successfully returns a device token
    func handleDeviceToken(_ tokenData: Data)
}
