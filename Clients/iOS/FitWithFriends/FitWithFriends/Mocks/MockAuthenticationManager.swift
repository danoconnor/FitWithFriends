//
//  MockAuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import AuthenticationServices
import Foundation

class MockAuthenticationManager: AuthenticationManager {
    init() {
        super.init(appleAuthenticationManager: MockAppleAuthenticationManager(),
                   authenticationService: MockAuthenticationService(),
                   tokenManager: MockTokenManager())
    }

    var return_loggedInUserId: UInt? = 0
    override var loggedInUserId: UInt? {
        get { return return_loggedInUserId }
        set {}
    }

    var return_error: Error?

    var userToLogin: UInt = 0
    override func beginLogin(with delegate: ASAuthorizationControllerPresentationContextProviding) {
        loginState = .inProgress

        Task.detached {
            await MockUtilities.delayOneSecond()
            // authenticationCompleted(result: .success(Token()))
        }
    }

    override func logout() {
        self.loginState = .notLoggedIn(nil)
        self.loggedInUserId = nil
    }

    override func refreshToken(token: Token) async -> Error? {
        await MockUtilities.delayOneSecond()
        return return_error
    }
}
