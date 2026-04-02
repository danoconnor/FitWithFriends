//
//  MockAppleAuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/26/22.
//

import AuthenticationServices
import Foundation

public class MockAppleAuthenticationManager: IAppleAuthenticationManager {
    public var authenticationDelegate: AppleAuthenticationDelegate?

    public init() {}

    public var param_beginAppleLogin_presentationDelegate: ASAuthorizationControllerPresentationContextProviding?
    public var param_beginAppleLogin_userProvidedName: PersonNameComponents?

    /// Controls what happens when `beginAppleLogin` is called.
    /// `.pending` (default) leaves login in progress (delegate is never called).
    /// `.success` immediately calls the delegate with the provided `return_loginToken`.
    /// `.failure` immediately calls the delegate with a generic error.
    public enum LoginOutcome {
        case pending
        case success
        case failure
    }
    public var return_loginOutcome: LoginOutcome = .pending
    public var return_loginToken: Token?

    public var beginAppleLoginCallCount = 0
    public func beginAppleLogin(
        presentationDelegate: ASAuthorizationControllerPresentationContextProviding,
        userProvidedName: PersonNameComponents? = nil
    ) {
        beginAppleLoginCallCount += 1
        param_beginAppleLogin_presentationDelegate = presentationDelegate
        param_beginAppleLogin_userProvidedName = userProvidedName

        switch return_loginOutcome {
        case .pending:
            break
        case .success:
            let token = return_loginToken ?? Token(accessToken: "TEST_TOKEN",
                                                   accessTokenExpiry: Date(timeIntervalSinceNow: 3600),
                                                   refreshToken: "TEST_REFRESH",
                                                   userId: "TEST_USER")
            authenticationDelegate?.authenticationCompleted(result: .success(token))
        case .failure:
            authenticationDelegate?.authenticationCompleted(result: .failure(NSError(domain: "MockAppleAuth", code: -1)))
        }
    }

    public var return_isAppleAccountValid: Bool = true

    public var isAppleAccountValidCallCount = 0
    public func isAppleAccountValid() -> Bool {
        isAppleAccountValidCallCount += 1
        return return_isAppleAccountValid
    }
}
