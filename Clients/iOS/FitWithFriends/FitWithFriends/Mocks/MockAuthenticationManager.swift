//
//  MockAuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import AuthenticationServices
import Foundation

public class MockAuthenticationManager: AuthenticationManager {
    public init() {
        super.init(appleAuthenticationManager: MockAppleAuthenticationManager(),
                   authenticationService: MockAuthenticationService(),
                   tokenManager: MockTokenManager())
    }

    public var return_loggedInUserId: String?
    override public var loggedInUserId: String? {
        get { return return_loggedInUserId }
        set {}
    }

    public var return_error: Error?

    public var userToLogin: UInt = 0
    override public func beginLogin(with delegate: ASAuthorizationControllerPresentationContextProviding) {
        loginState = .inProgress

        Task.detached {
            await MockUtilities.delayOneSecond()
            // authenticationCompleted(result: .success(Token()))
        }
    }

    override public func logout() {
        self.loginState = .notLoggedIn(nil)
        self.loggedInUserId = nil
    }

    override public func refreshToken(token: Token) async -> Error? {
        await MockUtilities.delayOneSecond()
        return return_error
    }
}
