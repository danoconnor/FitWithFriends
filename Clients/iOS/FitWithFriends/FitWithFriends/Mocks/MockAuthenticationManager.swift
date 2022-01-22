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

    var shouldFailLogin = false
    var userToLogin: UInt = 0
    override func login(username: String, password: String, completion: @escaping (Error?) -> Void) {
        loginState = .inProgress
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }

            if self.shouldFailLogin {
                self.loginState = .notLoggedIn
            } else {
                self.loggedInUserId = self.userToLogin
                self.loginState = .loggedIn
            }
        }
    }

    override func logout() {
        self.loginState = .notLoggedIn
        self.loggedInUserId = nil
    }

    var return_refreshTokenError: Error?
    override func refreshToken(token: Token, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            completion(self?.return_refreshTokenError)
        }
    }
}
