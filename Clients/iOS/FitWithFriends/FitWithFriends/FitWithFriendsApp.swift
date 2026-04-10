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

    static let objectGraph: IObjectGraph = {
        #if DEBUG
            if ProcessInfo.processInfo.environment["FWF_UNIT_TESTING"] == "1" {
                return MockObjectGraph()
            } else if ProcessInfo.processInfo.environment["FWF_UI_TESTING"] == "1" {
                return UITestingObjectGraph()
            } else {
                return ObjectGraph()
            }
        #else // release
            ObjectGraph()
        #endif
    }()

    init() {
        Logger.setupLogging()
    }

    var body: some Scene {
        WindowGroup {
            MainContentView(objectGraph: FitWithFriendsApp.objectGraph)
                .onOpenURL {
                    Logger.traceInfo(message: "Application launched with url \($0.absoluteString)")
                    _ = FitWithFriendsApp.objectGraph.appProtocolHandler.handleProtocol(url: $0)
                }
        }
    }
}
