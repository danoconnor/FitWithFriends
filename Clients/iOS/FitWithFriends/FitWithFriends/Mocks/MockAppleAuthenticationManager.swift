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

    public var beginAppleLoginCallCount = 0
    public func beginAppleLogin(
        presentationDelegate: ASAuthorizationControllerPresentationContextProviding,
        userProvidedName: PersonNameComponents? = nil
    ) {
        beginAppleLoginCallCount += 1
        param_beginAppleLogin_presentationDelegate = presentationDelegate
        param_beginAppleLogin_userProvidedName = userProvidedName
    }

    public var return_isAppleAccountValid: Bool = true

    public var isAppleAccountValidCallCount = 0
    public func isAppleAccountValid() -> Bool {
        isAppleAccountValidCallCount += 1
        return return_isAppleAccountValid
    }
}
