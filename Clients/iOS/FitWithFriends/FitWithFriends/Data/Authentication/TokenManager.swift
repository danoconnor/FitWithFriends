//
//  TokenManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

public class TokenManager: ITokenManager {
    private let keychainUtilities: IKeychainUtilities

    private var _token: Token?
    private let tokenQueue = DispatchQueue(label: "TokenManagerQueue")
    private var cachedToken: Token? {
        get { return tokenQueue.sync { _token } }
        set { tokenQueue.sync { _token = newValue } }
    }

    private let tokenKeychainGroup = "com.danoconnor.FitWithFriends"
    private let tokenKeychainService = "com.danoconnor.FitWithFriends"
    private let tokenKeychainAccount = "accessToken"

    public init(keychainUtilities: IKeychainUtilities) {
        self.keychainUtilities = keychainUtilities
    }

    public func getCachedToken() throws -> Token {
        // Use the in-memory token cache for performance
        if let token = cachedToken {
            Logger.traceInfo(message: "Found token in memory cache")

            if token.isAccessTokenExpired {
                throw TokenError.expired(token: token)
            }

            return token
        }

        do {
            // If we don't have a token in memory, check the keychain
            Logger.traceInfo(message: "Searching for token in keychain")
            let keychainToken: Token = try keychainUtilities.getKeychainItem(accessGroup: tokenKeychainGroup,
                                                                             service: tokenKeychainService,
                                                                             account: tokenKeychainAccount)

            Logger.traceInfo(message: "Found token data in keychain")

            if keychainToken.isAccessTokenExpired {
                throw TokenError.expired(token: keychainToken)
            }

            return keychainToken
        } catch {
            Logger.traceError(message: "Couldn't find token in keychain", error: error)
            throw error
        }
    }

    public func storeToken(_ token: Token) {
        // When we use the refresh token to get a new access token,
        // the server won't return the refresh token in the response.
        // In that case, re-use the previously known refresh token
        if token.refreshToken == nil {
            token.refreshToken = cachedToken?.refreshToken
            token.refreshTokenExpiry = cachedToken?.refreshTokenExpiry
        }

        cachedToken = token

        do {
            try keychainUtilities.writeKeychainItem(token,
                                                    accessGroup: tokenKeychainGroup,
                                                    service: tokenKeychainService,
                                                    account: tokenKeychainAccount,
                                                    updateExistingItemIfNecessary: true)
        } catch {
            Logger.traceError(message: "Could not save token to keychain", error: error)
        }
    }

    public func deleteAllTokens() {
        do {
            try keychainUtilities.deleteKeychainItem(accessGroup: tokenKeychainGroup,
                                                     service: tokenKeychainService,
                                                     account: tokenKeychainAccount)

            cachedToken = nil
            Logger.traceInfo(message: "Successfully deleted cached tokens")
        } catch {
            Logger.traceError(message: "Failed to delete tokens from keychain", error: error)
        }
    }
}
