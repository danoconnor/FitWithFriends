//
//  AuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Combine
import Foundation
import AuthenticationServices

class AuthenticationManager: ObservableObject {
    @Published var loginState = LoginState.notLoggedIn(nil) {
        didSet {
            Logger.traceInfo(message: "Login state changed: \(loginState)")
        }
    }

    private let appleAuthenticationManager: AppleAuthenticationManager
    private let authenticationService: AuthenticationService
    private let tokenManager: TokenManager

    var loggedInUserId: UInt?

    init(appleAuthenticationManager: AppleAuthenticationManager,
         authenticationService: AuthenticationService,
         tokenManager: TokenManager) {
        self.appleAuthenticationManager = appleAuthenticationManager
        self.authenticationService = authenticationService
        self.tokenManager = tokenManager

        setInitialLoginState()
    }

    func beginLogin(with delegate: ASAuthorizationControllerPresentationContextProviding) {
        loginState = .inProgress

        Logger.traceInfo(message: "Beginning Apple login")
        appleAuthenticationManager.beginAppleLogin(presentationDelegate: delegate)
    }

    func logout() {
        Logger.traceInfo(message: "Logging out")

        tokenManager.deleteAllTokens()
        loggedInUserId = nil
        loginState = .notLoggedIn(nil)
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
            loginState = .notLoggedIn(error)
        }

        return result.xtError
    }

    private func setInitialLoginState() {
        guard appleAuthenticationManager.isAppleAccountValid() else {
            Logger.traceWarning(message: "Apple account is not valid. Setting login state to notLoggedIn")
            loginState = .notLoggedIn(nil)
            return
        }

        // TODO: check Apple credential state to make sure user hasn't unlinked their Apple account from this app
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
                loginState = .notLoggedIn(nil)
            }
        }
    }
}

extension AuthenticationManager: AppleAuthenticationDelegate {
    func authenticationCompleted(result: Result<Token, Error>) {
        switch result {
        case let .success(token):
            tokenManager.storeToken(token)
            loggedInUserId = token.userId
            loginState = .loggedIn
        case let .failure(error):
            Logger.traceError(message: "Could not fetch token for user", error: error)
            loggedInUserId = nil
            loginState = .notLoggedIn(error)
        }
    }
}
