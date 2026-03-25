//
//  IServerEnvironmentManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 8/16/25.
//

import Foundation

/// Protocol for managing settings related to the backend environment to connect to
public protocol IServerEnvironmentManager {
    var baseUrl: String { get }
    var clientSecret: String { get }
    var clientId: String { get }
    var isLocalTesting: Bool { get }
}
