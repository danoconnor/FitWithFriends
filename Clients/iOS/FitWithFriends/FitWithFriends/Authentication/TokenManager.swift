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

    func getCachedToken() -> Result<Token, Error> {
        // Use the in-memory token cache for performance
        if let token = cachedToken {
            return token.isAccessTokenExpired ? .failure(TokenError.expired) : .success(token)
        }

        // If we don't have a token in memory, check the keychain
        let keychainResult = keychainUtilities.getKeychainItem(accessGroup: tokenKeychainGroup,
                                                               service: tokenKeychainService,
                                                               account: tokenKeychainAccount)

        switch keychainResult {
        case let .success(data):
            if let keychainToken = data as? Token {
                cachedToken = keychainToken
                return keychainToken.isAccessTokenExpired ? .failure(TokenError.expired) : .success(keychainToken)
            } else {
                fallthrough
            }
        case .failure:
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
