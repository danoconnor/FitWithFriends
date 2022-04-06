//
//  TokenManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

class TokenManager {
    private let keychainUtilities: KeychainUtilities

    private var _token: Token?
    private let tokenQueue = DispatchQueue(label: "TokenManagerQueue")
    private var cachedToken: Token? {
        get { return tokenQueue.sync { _token } }
        set { tokenQueue.sync { _token = newValue } }
    }

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
            return token.isAccessTokenExpired ? .failure(.expired(token: token)) : .success(token)
        }

        // If we don't have a token in memory, check the keychain
        Logger.traceInfo(message: "Searching for token in keychain")
        let keychainResult: Result<Token, KeychainError> = keychainUtilities.getKeychainItem(accessGroup: tokenKeychainGroup,
                                                                                             service: tokenKeychainService,
                                                                                             account: tokenKeychainAccount)

        switch keychainResult {
        case let .success(token):
            Logger.traceInfo(message: "Found token data in keychain")
            cachedToken = token
            return token.isAccessTokenExpired ? .failure(.expired(token: token)) : .success(token)
        case .failure:
            Logger.traceInfo(message: "No token found in keychain")
            return .failure(.notFound)
        }
    }

    func storeToken(_ token: Token) {
        // When we use the refresh token to get a new access token,
        // the server won't return the refresh token in the response.
        // In that case, re-use the previously known refresh token
        if token.refreshToken == nil {
            token.refreshToken = cachedToken?.refreshToken
            token.refreshTokenExpiry = cachedToken?.refreshTokenExpiry
        }

        cachedToken = token

        let keychainResult = keychainUtilities.writeKeychainItem(token,
                                                                 accessGroup: tokenKeychainGroup,
                                                                 service: tokenKeychainService,
                                                                 account: tokenKeychainAccount,
                                                                 updateExistingItemIfNecessary: true)

        if let error = keychainResult {
            Logger.traceError(message: "Could not save token to keychain", error: error)
        }
    }

    func deleteAllTokens() {
        if let error = keychainUtilities.deleteKeychainItem(accessGroup: tokenKeychainGroup,
                                                            service: tokenKeychainService,
                                                            account: tokenKeychainAccount) {
            Logger.traceError(message: "Failed to delete tokens from keychain", error: error)
            return
        }

        cachedToken = nil
        Logger.traceInfo(message: "Successfully deleted cached tokens")
    }
}
