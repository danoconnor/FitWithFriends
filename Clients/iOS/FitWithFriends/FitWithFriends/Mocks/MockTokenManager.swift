//
//  MockTokenManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockTokenManager: ITokenManager {
    public init() {}

    var return_token: Token?
    var return_cachedTokenError: TokenError?
    public func getCachedToken() throws -> Token {
        if let token = return_token {
            return token
        } else {
            throw return_cachedTokenError ?? TokenError.notFound
        }
    }

    public func storeToken(_ token: Token) {}

    public func deleteAllTokens() {}
}
