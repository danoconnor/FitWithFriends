//
//  MockTokenManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockTokenManager: TokenManager {
    init() {
        super.init(keychainUtilities: MockKeychainUtilities())
    }

    var return_token: Token?
    var return_cachedTokenError: TokenError?
    override func getCachedToken() -> Result<Token, TokenError> {
        if let token = return_token {
            return .success(token)
        } else {
            return .failure(return_cachedTokenError ?? TokenError.notFound)
        }
    }

    override func storeToken(_ token: Token) {}

    override func deleteAllTokens() {}
}
