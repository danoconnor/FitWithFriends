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

    public func beginAppleLogin(
        presentationDelegate: ASAuthorizationControllerPresentationContextProviding,
        userProvidedName: PersonNameComponents? = nil
    ) {
        param_beginAppleLogin_presentationDelegate = presentationDelegate
        param_beginAppleLogin_userProvidedName = userProvidedName
    }

    public var return_isAppleAccountValid: Bool = true

    public func isAppleAccountValid() -> Bool {
        return return_isAppleAccountValid
    }
}
