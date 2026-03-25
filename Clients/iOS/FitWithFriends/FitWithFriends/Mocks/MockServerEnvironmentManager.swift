//
//  MockServerEnvironmentManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 8/16/25.
//

import Foundation

/// Mock implementation of IServerEnvironmentManager for testing purposes
public class MockServerEnvironmentManager: IServerEnvironmentManager {
    public var baseUrl: String = "https://mock.local"
    public var clientSecret: String = "mockClientSecret"
    public var clientId: String = "mockClientId"
    public var isLocalTesting: Bool = true

    public init() {}
}
