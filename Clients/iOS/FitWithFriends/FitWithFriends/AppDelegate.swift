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
        Logger.traceInfo(message: "------------------------------ didFinishLaunchingWithOptions (options: \(launchOptions?.map { $0.key }.description ?? "none")) ------------------------------")

        // Apple's docs suggest that we register our queries in didFinishLaunchingWithOptions so that they will be executed
        // properly when the app is launched in the background
        // https://developer.apple.com/documentation/healthkit/hkobserverquery/executing_observer_queries
        FitWithFriendsApp.objectGraph.healthKitManager.setupObserverQueries()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Logger.traceInfo(message: "------------------------------ applicationDidBecomeActive ------------------------------")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Logger.traceInfo(message: "------------------------------ applicationDidEnterBackground ------------------------------")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Logger.traceInfo(message: "------------------------------ applicationWillTerminate ------------------------------")
    }
}
