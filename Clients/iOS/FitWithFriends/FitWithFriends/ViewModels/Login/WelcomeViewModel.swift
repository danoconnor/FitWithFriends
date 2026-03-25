//
//  WelcomeViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/13/22.
//

import AuthenticationServices
import Combine
import Foundation

public class WelcomeViewModel: NSObject, ObservableObject {
    private static let firstLaunchUserDefaultKey =  "HasShownFirstLaunch"

    @Published public var loginState: LoginViewState = .notStarted
    @Published public var sheetToDisplay: LoginSheet?

    private let authenticationManager: IAuthenticationManager

    private var loginStateCancellable: AnyCancellable?

    init(authenticationManager: IAuthenticationManager) {
        self.authenticationManager = authenticationManager
        super.init()

        loginStateCancellable = authenticationManager.loginStatePublisher.sink { [weak self] loginState in
            switch loginState {
            case .loggedIn:
                self?.setState(.success)
            case .inProgress:
                self?.setState(.inProgress)
            case .needUserInfo:
                self?.setState(.needUserInfo)
            case let .notLoggedIn(loginError):
                self?.setState(loginError == nil ? .notStarted : .failed(errorMessage: "Login failed. Please try again"))
            }
        }
    }

    public func login() {
        setState(.inProgress)
        authenticationManager.beginLogin(with: self, userProvidedName: nil)
    }

    public func dismissSheet() {
        // No action needed if we aren't currently displaying a sheet
        guard let sheetToDisplay = sheetToDisplay else { return }

        switch sheetToDisplay {
        case .firstLaunchWelcomeView:
            UserDefaults.standard.set(true, forKey: WelcomeViewModel.firstLaunchUserDefaultKey)
        case .userInputView:
            authenticationManager.cancelUserInput()
        case .none:
            break
        }

        // Force no sheet to be shown, since the `cancelUserInput` call is async and can take a second to be applied
        updateSheet(forceSheet: nil)
    }

    public func createUserAndLogin(firstName: String, lastName: String) {
        // Dismiss the user input view
        updateSheet(forceSheet: nil)

        let personName = PersonNameComponents(givenName: firstName, familyName: lastName)
        authenticationManager.beginLogin(with: self, userProvidedName: personName)
    }

    private func setState(_ newState: LoginViewState) {
        DispatchQueue.main.async { [weak self] in
            self?.loginState = newState

            // The sheet we display may change based on login state, so update now
            self?.updateSheet()
        }
    }

    private func updateSheet(forceSheet: LoginSheet? = nil) {
        var newSheet: LoginSheet? = nil

        if let forceSheet = forceSheet {
            // Treat none as not showing a sheet
            newSheet = forceSheet == .none ? nil : forceSheet
        } else if !UserDefaults.standard.bool(forKey: WelcomeViewModel.firstLaunchUserDefaultKey) {
            newSheet = .firstLaunchWelcomeView
        } else if loginState == .needUserInfo {
            newSheet = .userInputView
        }

        if newSheet != sheetToDisplay {
            DispatchQueue.main.async { [weak self] in
                self?.sheetToDisplay = newSheet
            }
        }
    }
}

extension WelcomeViewModel: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.activeKeyWindow ?? UIWindow()
    }
}
