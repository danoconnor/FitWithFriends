//
//  MockAuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

#if !os(watchOS)
import AuthenticationServices
#endif
import Combine
import Foundation

public class MockAuthenticationManager: IAuthenticationManager {
    @Published public var loginState: LoginState = .notLoggedIn(nil)
    public var loginStatePublisher: Published<LoginState>.Publisher { $loginState }
    public var loggedInUserId: String?

    public init() {}

    #if !os(watchOS)
    public var param_beginLogin_delegate: ASAuthorizationControllerPresentationContextProviding?
    public var param_beginLogin_userProvidedName: PersonNameComponents?

    public var beginLoginCallCount = 0
    public func beginLogin(
        with delegate: ASAuthorizationControllerPresentationContextProviding,
        userProvidedName: PersonNameComponents? = nil
    ) {
        beginLoginCallCount += 1
        param_beginLogin_delegate = delegate
        param_beginLogin_userProvidedName = userProvidedName

        loginState = .inProgress
    }
    #endif

    public var return_cancelUserInput_called: Bool = false

    public var cancelUserInputCallCount = 0
    public func cancelUserInput() {
        cancelUserInputCallCount += 1
        return_cancelUserInput_called = true
    }

    public var return_logout_called: Bool = false

    public var logoutCallCount = 0
    public func logout() {
        logoutCallCount += 1
        return_logout_called = true
        self.loginState = .notLoggedIn(nil)
        self.loggedInUserId = nil
    }
}
