//
//  AppDelegate.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/26/20.
//

import Foundation
import UIKit

class AppDelegate: NSObject { }

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        ObjectGraph.sharedInstance.pushNotificationManager.registerPushTokenIfNecessary(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Logger.traceError(message: "Failed to register for remote notifications", error: error)
    }
}
