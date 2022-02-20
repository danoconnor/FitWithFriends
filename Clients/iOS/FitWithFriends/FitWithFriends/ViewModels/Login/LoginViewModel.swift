//
//  LoginViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Combine
import Foundation

class LoginViewModel: ObservableObject {
    @Published var state: ViewOperationState = .notStarted

    private let authenticationManager: AuthenticationManager

    init(authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
    }

    func login(username: String, password: String) {
        setState(.inProgress)
        Task.detached { [weak self] in
            guard let self = self else { return }

            let error = await self.authenticationManager.login(username: username, password: password)
            if let error = error {
                Logger.traceError(message: "Login failed", error: error)
                self.setState(.failed(errorMessage: "Login failed. Please try again"))
            } else {
                self.setState(.success)
            }
        }
    }

    private func setState(_ newState: ViewOperationState) {
        DispatchQueue.main.async { [weak self] in
            self?.state = newState
        }
    }
}
