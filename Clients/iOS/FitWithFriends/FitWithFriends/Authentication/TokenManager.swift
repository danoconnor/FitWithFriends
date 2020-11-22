//
//  TokenManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

class TokenManager {
    private let keychainUtilities: KeychainUtilities

    private var cachedToken: Token?

    private let tokenKeychainGroup = "com.danoconnor.FitWithFriends"
    private let tokenKeychainService = "com.danoconnor.FitWithFriends"
    private let tokenKeychainAccount = "accessToken"

    init(keychainUtilities: KeychainUtilities) {
        self.keychainUtilities = keychainUtilities
    }

    func getCachedToken() -> Result<Token, TokenError> {
        // Use the in-memory token cache for performance
        if let token = cachedToken {
            Logger.traceInfo(message: "Found token in memory cache")
            return token.isAccessTokenExpired ? .failure(TokenError.expired(token: token)) : .success(token)
        }

        // If we don't have a token in memory, check the keychain
        Logger.traceInfo(message: "Searching for token in keychain")
        let keychainResult = keychainUtilities.getKeychainItem(accessGroup: tokenKeychainGroup,
                                                               service: tokenKeychainService,
                                                               account: tokenKeychainAccount)

        switch keychainResult {
        case let .success(data):
            if let keychainToken = data as? Token {
                Logger.traceInfo(message: "Found token in keychain")
                cachedToken = keychainToken
                return keychainToken.isAccessTokenExpired ? .failure(TokenError.expired(token: keychainToken)) : .success(keychainToken)
            } else {
                fallthrough
            }
        case .failure:
            Logger.traceInfo(message: "No token found in keychain")
            return .failure(TokenError.notFound)
        }
    }

    func storeToken(_ token: Token) {
        cachedToken = token
        let keychainResult = keychainUtilities.writeKeychainItem(data: token,
                                                                 accessGroup: tokenKeychainGroup,
                                                                 service: tokenKeychainService,
                                                                 account: tokenKeychainAccount,
                                                                 updateExistingItemIfNecessary: true)

        if let error = keychainResult {
            Logger.traceError(message: "Could not save token to keychain", error: error)
        }
    }
}
