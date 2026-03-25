//
//  MockTokenManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockTokenManager: ITokenManager {
    public init() {}

    var return_token: Token? = Token(accessToken: "ACCESS_TOKEN",
                                     accessTokenExpiry: Date(timeIntervalSinceNow: 60 * 60),
                                     refreshToken: "REFRESH_TOKEN", 
                                     userId: "ABCDEF1234")
    var return_cachedTokenError: TokenError?
    public var getCachedTokenCallCount = 0
    public func getCachedToken() throws -> Token {
        getCachedTokenCallCount += 1
        if let token = return_token {
            return token
        } else {
            throw return_cachedTokenError ?? TokenError.notFound
        }
    }

    public var storeTokenCallCount = 0
    public func storeToken(_ token: Token) {
        storeTokenCallCount += 1
    }

    public var deleteAllTokensCallCount = 0
    public func deleteAllTokens() {
        deleteAllTokensCallCount += 1
    }
}
