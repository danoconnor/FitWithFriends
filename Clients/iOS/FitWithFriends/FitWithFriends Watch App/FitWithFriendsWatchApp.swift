//
//  FitWithFriendsWatchApp.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import SwiftUI

@main
struct FitWithFriendsWatchApp: App {
    @StateObject private var objectGraph = WatchObjectGraph()

    var body: some Scene {
        WindowGroup {
            WatchRootView(objectGraph: objectGraph)
        }
    }
}
