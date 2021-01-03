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

    func login(username: String, password: String) {
        setState(.inProgress)
        ObjectGraph.sharedInstance.authenticationManager.login(username: username, password: password) { [weak self] error in
            if let error = error {
                Logger.traceError(message: "Login failed", error: error)
                self?.setState(.failed(errorMessage: "Login failed. Please try again"))
            } else {
                self?.setState(.success)
            }
        }
    }

    private func setState(_ newState: ViewOperationState) {
        DispatchQueue.main.async { [weak self] in
            self?.state = newState
        }
    }
}
