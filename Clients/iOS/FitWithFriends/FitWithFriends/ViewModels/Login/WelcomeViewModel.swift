//
//  WelcomeViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/13/22.
//

import AuthenticationServices
import Combine
import Foundation

class WelcomeViewModel: NSObject, ObservableObject {
    @Published var state: ViewOperationState = .notStarted

    private let authenticationManager: AuthenticationManager

    private var loginStateCancellable: AnyCancellable?

    init(authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        super.init()

        loginStateCancellable = authenticationManager.$loginState.sink { [weak self] loginState in
            switch loginState {
            case .loggedIn:
                self?.setState(.success)
            case .inProgress:
                self?.setState(.inProgress)
            case let .notLoggedIn(loginError):
                self?.setState(loginError == nil ? .notStarted : .failed(errorMessage: "Login failed. Please try again"))
            }
        }
    }

    func login() {
        setState(.inProgress)
        authenticationManager.beginLogin(with: self)
    }

    private func setState(_ newState: ViewOperationState) {
        DispatchQueue.main.async { [weak self] in
            self?.state = newState
        }
    }
}

extension WelcomeViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.keyWindow ?? UIWindow()
    }
}

