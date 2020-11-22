//
//  CreateAccountViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Combine
import Foundation
import SwiftUI

class CreateAccountViewModel: ObservableObject {
    enum AccountCreationState: Equatable {
        case notStarted
        case inProgress
        case failed(errorMessage: String)
        case success

        var isFailed: Bool {
            switch self {
            case .failed: return true
            default: return false
            }
        }

        var errorMessage: String {
            switch self {
            case let .failed(errorMessage):
                return errorMessage
            default:
                return ""
            }
        }
    }

    @Published var state: AccountCreationState = .notStarted

    func createAccount(username: String, password: String, passwordConfirmation: String, displayName: String) {
        if let errorMessage = validateInput(username: username, password: password, passwordConfirmation: passwordConfirmation, displayName: displayName) {
            state = .failed(errorMessage: errorMessage)
            return
        }

        state = .inProgress
        ObjectGraph.sharedInstance.serviceCommunicator.createUser(username: username, password: password, displayName: displayName) { [weak self] result in
            switch result {
            case .success:
                // TODO: do something with the returned user - store user ID?
                self?.state = .success
            case let .failure(error):
                Logger.traceError(message: "Failed to create new user", error: error)
                self?.state = .failed(errorMessage: "Could not create user")
            }
        }
    }

    /// Returns an error message if input is not valid or nil if all input is valid
    private func validateInput(username: String, password: String, passwordConfirmation: String, displayName: String) -> String? {
        guard username.count > 0 else {
            return "Please provide a username"
        }

        guard password.count > 8 else {
            return "Please set a password at least 8 characters long"
        }

        guard password == passwordConfirmation else {
            return "Passwords don't match!"
        }

        guard displayName.count > 0 else {
            return "Please provide a name to display"
        }

        // No error
        return nil
    }
}
