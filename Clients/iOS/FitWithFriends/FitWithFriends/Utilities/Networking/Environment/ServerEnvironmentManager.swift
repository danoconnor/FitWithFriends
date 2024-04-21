//
//  ServerEnvironmentManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/14/24.
//

import Foundation

/// Manages settings related to the backend environment to connect to
public class ServerEnvironmentManager {
    /// The key used to lookup the boolean value in UserDefautls for whether to use the local test environment or the production environment
    /// Matches what is defined in RootSettings/Settings.bundle/Root.plist
    private static let useLocalEnvironmentKey = "uselocalserverenvironment"

    private let serverEnvironment: ServerEnvironment

    public var baseUrl: String {
        switch serverEnvironment {
        case .localTesting(let baseUrl, _, _),
                .production(let baseUrl, _, _):
            return baseUrl
        }
    }

    public var clientSecret: String {
        switch serverEnvironment {
        case .localTesting(_, let clientSecret, _),
                .production(_, let clientSecret, _):
            return clientSecret
        }
    }

    public var clientId: String {
        switch serverEnvironment {
        case .localTesting(_, _, let clientId),
                .production(_, _, let clientId):
            return clientId
        }
    }

    public var isLocalTesting: Bool {
        switch serverEnvironment {
        case .localTesting:
            return true
        case .production:
            return false
        }
    }

    public init(userDefaults: UserDefaults) {
        // Use the boolean switch from the Root settings (values for our app in iOS Settings)
        // This should only be defined for Debug builds. Release builds should not have this value and will default to production
        let shouldUseLocalEnvironment = userDefaults.value(forKey: ServerEnvironmentManager.useLocalEnvironmentKey) as? Bool ?? false

        if shouldUseLocalEnvironment {
            serverEnvironment = .localTesting(baseUrl: SecretConstants.localServiceBaseUrl,
                                              clientSecret: SecretConstants.localClientSecret,
                                              clientId: SecretConstants.localClientId)
        } else {
            serverEnvironment = .production(baseUrl: SecretConstants.prodServiceBaseUrl,
                                            clientSecret: SecretConstants.prodClientSecret,
                                            clientId: SecretConstants.prodClientId)
        }
    }
}
