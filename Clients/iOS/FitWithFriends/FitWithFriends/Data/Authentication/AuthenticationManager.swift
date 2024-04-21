//
//  AuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Combine
import Foundation
import AuthenticationServices

public class AuthenticationManager: ObservableObject {
    @Published public var loginState = LoginState.notLoggedIn(nil) {
        didSet {
            Logger.traceInfo(message: "Login state changed: \(loginState)")
        }
    }

    private let appleAuthenticationManager: AppleAuthenticationManager
    private let authenticationService: IAuthenticationService
    private let tokenManager: ITokenManager

    public var loggedInUserId: String?

    public init(appleAuthenticationManager: AppleAuthenticationManager,
         authenticationService: IAuthenticationService,
         tokenManager: ITokenManager) {
        self.appleAuthenticationManager = appleAuthenticationManager
        self.authenticationService = authenticationService
        self.tokenManager = tokenManager

        setInitialLoginState()
    }

    public func beginLogin(with delegate: ASAuthorizationControllerPresentationContextProviding) {
        loginState = .inProgress

        Logger.traceInfo(message: "Beginning Apple login")
        appleAuthenticationManager.beginAppleLogin(presentationDelegate: delegate)
    }

    public func logout() {
        Logger.traceInfo(message: "Logging out")

        tokenManager.deleteAllTokens()
        loggedInUserId = nil
        loginState = .notLoggedIn(nil)
    }

    private func refreshToken(token: Token) async {
        do {
            let token = try await authenticationService.getToken(token: token)

            Logger.traceInfo(message: "Successfully refreshed token")
            loggedInUserId = token.userId
            tokenManager.storeToken(token)
            loginState = .loggedIn
        } catch {
            Logger.traceError(message: "Could not refresh token", error: error)
            loggedInUserId = nil
            loginState = .notLoggedIn(error)
        }
    }

    private func setInitialLoginState() {
        guard appleAuthenticationManager.isAppleAccountValid() else {
            Logger.traceWarning(message: "Apple account is not valid. Setting login state to notLoggedIn")
            loginState = .notLoggedIn(nil)
            return
        }

        do {
            let cachedToken = try tokenManager.getCachedToken()

            // If we have a cached token then we are already logged in
            loggedInUserId = cachedToken.userId
            loginState = .loggedIn
        } catch {
            if let tokenError = error as? TokenError,
               case let .expired(token) = tokenError {
                loginState = .inProgress
                Task.detached {
                    await self.refreshToken(token: token)
                }
            } else {
                Logger.traceInfo(message: "User is not logged in")
                loggedInUserId = nil
                loginState = .notLoggedIn(nil)
            }
        }
    }
}

extension AuthenticationManager: AppleAuthenticationDelegate {
    public func authenticationCompleted(result: Result<Token, Error>) {
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
