//
//  AuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Combine
import Foundation

class AuthenticationManager: ObservableObject {
    @Published var loginState = LoginState.notLoggedIn {
        didSet {
            Logger.traceInfo(message: "Login state changed: \(loginState)")
        }
    }

    private let authenticationService: AuthenticationService
    private let tokenManager: TokenManager

    var loggedInUserId: UInt?

    init(authenticationService: AuthenticationService,
         tokenManager: TokenManager) {
        self.authenticationService = authenticationService
        self.tokenManager = tokenManager

        setInitialLoginState()
    }

    func login(username: String, password: String, completion: @escaping (Error?) -> Void) {
        loginState = .inProgress
        authenticationService.getToken(username: username, password: password) { [weak self] result in
            switch result {
            case let .success(token):
                self?.tokenManager.storeToken(token)
                self?.loggedInUserId = token.userId
                self?.loginState = .loggedIn
                completion(nil)
            case let .failure(error):
                Logger.traceError(message: "Could not fetch token for user", error: error)
                self?.loggedInUserId = nil
                self?.loginState = .notLoggedIn
                completion(nil)
            }
        }
    }

    func logout() {
        tokenManager.deleteAllTokens()
        loggedInUserId = nil
        loginState = .notLoggedIn
    }

    func refreshToken(token: Token, completion: @escaping (Error?) -> Void) {
        authenticationService.getToken(token: token) { [weak self] result in
            switch result {
            case let .success(token):
                self?.loggedInUserId = token.userId
                self?.tokenManager.storeToken(token)
                self?.loginState = .loggedIn
                completion(nil)
            case let .failure(error):
                Logger.traceError(message: "Could not refresh token", error: error)
                self?.loggedInUserId = nil
                self?.loginState = .notLoggedIn
                completion(error)
            }
        }
    }

    private func setInitialLoginState() {
        // If we have a cached token then we are already logged in
        let cachedTokenResult = tokenManager.getCachedToken()
        switch cachedTokenResult {
        case let .success(token):
            loggedInUserId = token.userId
            loginState = .loggedIn
        case let .failure(error):
            switch error {
            case let .expired(token: token):
                loginState = .inProgress
                refreshToken(token: token) { error in
                    if let error = error {
                        Logger.traceError(message: "Failed to login using refresh token", error: error)
                    } else {
                        Logger.traceInfo(message: "Successfully logged in using refresh token")
                    }
                }
            default:
                logout()
            }
        }
    }
}
