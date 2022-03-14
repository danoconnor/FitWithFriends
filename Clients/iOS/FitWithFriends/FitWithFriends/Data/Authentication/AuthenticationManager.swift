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

    func login(username: String, password: String) async -> Error? {
        loginState = .inProgress
        let result: Result<Token, Error> = await authenticationService.getToken(username: username, password: password)

        switch result {
        case let .success(token):
            tokenManager.storeToken(token)
            loggedInUserId = token.userId
            loginState = .loggedIn
        case let .failure(error):
            Logger.traceError(message: "Could not fetch token for user", error: error)
            loggedInUserId = nil
            loginState = .notLoggedIn
        }

        return result.xtError
    }

    func logout() {
        Logger.traceInfo(message: "Logging out")

        tokenManager.deleteAllTokens()
        loggedInUserId = nil
        loginState = .notLoggedIn
    }

    func refreshToken(token: Token) async -> Error? {
        let result: Result<Token, Error> = await authenticationService.getToken(token: token)

        switch result {
        case let .success(token):
            Logger.traceInfo(message: "Successfully refreshed token")
            loggedInUserId = token.userId
            tokenManager.storeToken(token)
            loginState = .loggedIn
        case let .failure(error):
            Logger.traceError(message: "Could not refresh token", error: error)
            loggedInUserId = nil
            loginState = .notLoggedIn
        }

        return result.xtError
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
                Task.detached {
                    await self.refreshToken(token: token)
                }
            default:
                Logger.traceInfo(message: "User is not logged in")
                loggedInUserId = nil
                loginState = .notLoggedIn
            }
        }
    }
}
