//
//  ServerEnvironment.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/14/24.
//

import Foundation

public enum ServerEnvironment {
    /// Connect a test server instance running on the local network
    case localTesting(baseUrl: String, clientSecret: String, clientId: String)

    /// Connect to the production servers
    case production(baseUrl: String, clientSecret: String, clientId: String)
}
