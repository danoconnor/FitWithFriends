//
//  MockAuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import AuthenticationServices
import Combine
import Foundation

public class MockAuthenticationManager: IAuthenticationManager {
    @Published public var loginState: LoginState = .notLoggedIn(nil)
    public var loginStatePublisher: Published<LoginState>.Publisher { $loginState }
    public var loggedInUserId: String?

    public init() {}

    public var param_beginLogin_delegate: ASAuthorizationControllerPresentationContextProviding?
    public var param_beginLogin_userProvidedName: PersonNameComponents?

    public func beginLogin(
        with delegate: ASAuthorizationControllerPresentationContextProviding,
        userProvidedName: PersonNameComponents? = nil
    ) {
        param_beginLogin_delegate = delegate
        param_beginLogin_userProvidedName = userProvidedName

        loginState = .inProgress
    }

    public var return_cancelUserInput_called: Bool = false

    public func cancelUserInput() {
        return_cancelUserInput_called = true
    }

    public var return_logout_called: Bool = false

    public func logout() {
        return_logout_called = true
        self.loginState = .notLoggedIn(nil)
        self.loggedInUserId = nil
    }
}
