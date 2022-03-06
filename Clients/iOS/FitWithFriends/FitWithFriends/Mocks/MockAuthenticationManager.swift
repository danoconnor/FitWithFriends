//
//  MockAuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockAuthenticationManager: AuthenticationManager {
    init() {
        super.init(authenticationService: MockAuthenticationService(), tokenManager: MockTokenManager())
    }

    var return_loggedInUserId: UInt? = 0
    override var loggedInUserId: UInt? {
        get { return return_loggedInUserId }
        set {}
    }

    var return_error: Error?

    var userToLogin: UInt = 0
    override func login(username: String, password: String) async -> Error? {
        loginState = .inProgress

        await MockUtilities.delayOneSecond()

        if return_error != nil {
            loginState = .notLoggedIn
        } else {
            loggedInUserId = userToLogin
            loginState = .loggedIn
        }

        return return_error
    }

    override func logout() {
        self.loginState = .notLoggedIn
        self.loggedInUserId = nil
    }

    override func refreshToken(token: Token) async -> Error? {
        await MockUtilities.delayOneSecond()
        return return_error
    }
}
