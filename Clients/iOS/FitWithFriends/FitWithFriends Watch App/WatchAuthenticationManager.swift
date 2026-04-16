//
//  WatchAuthenticationManager.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import Combine
import Foundation
#if !os(watchOS)
import AuthenticationServices
#endif

/// A minimal IAuthenticationManager implementation for the Watch. The Watch cannot
/// initiate Sign in with Apple — that flow happens on the phone. This class only
/// observes the existing shared Keychain token and either declares the user
/// logged-in or prompts them to sign in on the phone.
class WatchAuthenticationManager: IAuthenticationManager, ObservableObject {
    @Published var loginState = LoginState.notLoggedIn(nil) {
        didSet {
            Logger.traceInfo(message: "Watch login state changed: \(loginState)")
        }
    }

    var loginStatePublisher: Published<LoginState>.Publisher {
        $loginState
    }

    var loggedInUserId: String?

    private let tokenManager: ITokenManager
    private let authenticationService: IAuthenticationService

    init(tokenManager: ITokenManager, authenticationService: IAuthenticationService) {
        self.tokenManager = tokenManager
        self.authenticationService = authenticationService
    }

    /// Read the token from Keychain (populated by the paired iPhone app) and publish the
    /// resulting login state. If the access token has expired we transparently refresh it
    /// using the stored refresh token so the Watch keeps working for long-offline users.
    func evaluateInitialLoginState() {
        do {
            let cachedToken = try tokenManager.getCachedToken()
            loggedInUserId = cachedToken.userId
            loginState = .loggedIn
        } catch {
            if let tokenError = error as? TokenError,
               case let .expired(token) = tokenError {
                loginState = .inProgress
                Task.detached { [weak self] in
                    await self?.refreshToken(token: token)
                }
            } else {
                Logger.traceInfo(message: "Watch: no stored token — user must sign in on iPhone")
                loggedInUserId = nil
                loginState = .notLoggedIn(nil)
            }
        }
    }

    private func refreshToken(token: Token) async {
        do {
            let refreshed = try await authenticationService.getToken(token: token)
            tokenManager.storeToken(refreshed)
            await MainActor.run {
                self.loggedInUserId = refreshed.userId
                self.loginState = .loggedIn
            }
        } catch {
            Logger.traceError(message: "Watch: failed to refresh token", error: error)
            await MainActor.run {
                self.loggedInUserId = nil
                self.loginState = .notLoggedIn(error)
            }
        }
    }

    // MARK: IAuthenticationManager — no-op login surface

    #if !os(watchOS)
    func beginLogin(
        with delegate: ASAuthorizationControllerPresentationContextProviding,
        userProvidedName: PersonNameComponents?
    ) {
        // Watch auth manager is read-only — sign-in happens on the phone.
        Logger.traceWarning(message: "beginLogin called on WatchAuthenticationManager — no-op")
    }
    #endif

    func cancelUserInput() {
        loginState = .notLoggedIn(nil)
    }

    func logout() {
        Logger.traceInfo(message: "Watch: logging out (clearing local token cache)")
        tokenManager.deleteAllTokens()
        loggedInUserId = nil
        loginState = .notLoggedIn(nil)
    }
}
