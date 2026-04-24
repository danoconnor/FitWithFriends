//
//  FitWithFriendsWatchApp.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import SwiftUI

@main
struct FitWithFriendsWatchApp: App {
    @StateObject private var objectGraph: WatchObjectGraph = {
        #if DEBUG
        if ProcessInfo.processInfo.environment["FWF_UI_TESTING"] == "1" {
            return UITestingWatchObjectGraph()
        }
        #endif
        return WatchObjectGraph()
    }()

    var body: some Scene {
        WindowGroup {
            WatchRootView(objectGraph: objectGraph)
        }
    }
}
