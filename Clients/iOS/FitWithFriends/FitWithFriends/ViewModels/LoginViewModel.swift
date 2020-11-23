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
        // Test code:
        let test = ObjectGraph.sharedInstance.tokenManager.getCachedToken()
        return

        setState(.inProgress)
        ObjectGraph.sharedInstance.serviceCommunicator.getToken(username: username, password: password) { [weak self] result in
            switch result {
            case let .success(token):
                ObjectGraph.sharedInstance.tokenManager.storeToken(token)
                self?.setState(.success)
            case let .failure(error):
                Logger.traceError(message: "Could not fetch token for user", error: error)
                self?.setState(.failed(errorMessage: "Login failed"))
            }
        }
    }

    private func setState(_ newState: ViewOperationState) {
        DispatchQueue.main.async { [weak self] in
            self?.state = newState
        }
    }
}
