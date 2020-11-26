//
//  FitWithFriendsApp.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import SwiftUI

@main
struct FitWithFriendsApp: App {
    init() {
        Logger.setupLogging()
    }

    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
    }
}
