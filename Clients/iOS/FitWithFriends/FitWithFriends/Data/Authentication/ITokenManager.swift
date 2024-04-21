//
//  ITokenManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/10/24.
//

import Foundation

/// Handles reading and writing tokens to the keychain
public protocol ITokenManager {
    /// Returns any cached token that we may have, or throws an error if we do not have any cached token
    /// - Returns: A cached token
    func getCachedToken() throws -> Token

    /// Stores the provided token in the keychain
    /// - Parameter token: The token to store
    func storeToken(_ token: Token)

    /// Delete all tokens from the keychain and in-memory cache
    func deleteAllTokens()
}
