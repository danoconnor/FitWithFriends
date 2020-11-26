//
//  FitWithFriendsApp.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import SwiftUI

@main
struct FitWithFriendsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        Logger.setupLogging()
    }

    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
    }
}
