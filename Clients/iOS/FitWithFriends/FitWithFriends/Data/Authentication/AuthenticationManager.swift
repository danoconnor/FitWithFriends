//
//  AuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Combine
import Foundation

class AuthenticationManager: ObservableObject {
    enum LoginState {
        case notLoggedIn
        case inProgress
        case loggedIn
    }

    @Published var loginState = LoginState.notLoggedIn

    private let serviceCommunicator: ServiceCommunicator
    private let tokenManager: TokenManager

    init(serviceCommunicator: ServiceCommunicator,
         tokenManager: TokenManager) {
        self.serviceCommunicator = serviceCommunicator
        self.tokenManager = tokenManager

        setInitialLoginState()
    }

    func login(username: String, password: String, completion: @escaping (Error?) -> Void) {
        loginState = .inProgress
        serviceCommunicator.getToken(username: username, password: password) { [weak self] result in
            switch result {
            case let .success(token):
                self?.tokenManager.storeToken(token)
                self?.loginState = .loggedIn
                completion(nil)
            case let .failure(error):
                Logger.traceError(message: "Could not fetch token for user", error: error)
                self?.loginState = .loggedIn
                completion(nil)
            }
        }
    }

    func logout() {
        tokenManager.deleteAllTokens()
        loginState = .notLoggedIn
    }

    func refreshToken(token: Token, completion: @escaping (Error?) -> Void) {
        serviceCommunicator.getToken(token: token) { [weak self] result in
            switch result {
            case let .success(token):
                self?.tokenManager.storeToken(token)
                self?.loginState = .loggedIn
                completion(nil)
            case let .failure(error):
                Logger.traceError(message: "Could not refresh token", error: error)
                self?.loginState = .notLoggedIn
                completion(error)
            }
        }
    }

    private func setInitialLoginState() {
        // If we have a cached token then we are already logged in
        let cachedTokenResult = tokenManager.getCachedToken()
        switch cachedTokenResult {
        case .success:
            loginState = .loggedIn
        case let .failure(error):
            switch error {
            case let .expired(token: token):
                loginState = .inProgress
                refreshToken(token: token) { _ in }
            default:
                loginState = .notLoggedIn
            }
        }
    }
}
