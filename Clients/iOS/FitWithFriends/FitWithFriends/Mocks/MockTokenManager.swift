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
