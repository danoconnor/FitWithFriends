//
//  MockAuthenticationService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockAuthenticationService: AuthenticationService {
    init() {
        super.init(httpConnector: MockHttpConnector(), tokenManager: MockTokenManager())
    }

    var return_token: Token?
    var return_error: Error?
    override func getToken(token: Token) async -> Result<Token, Error> {
        await MockUtilities.delayOneSecond()

        if let token = return_token {
            return .success(token)
        } else {
            return .failure(self.return_error ?? HttpError.generic)
        }
    }
}
