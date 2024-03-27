//
//  MockAppleAuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/26/22.
//

import AuthenticationServices
import Foundation

public class MockAppleAuthenticationManager: AppleAuthenticationManager {
    public init() {
        super.init(authenticationService: MockAuthenticationService(), keychainUtilities: MockKeychainUtilities(), userService: MockUserService())
    }

    override public func beginAppleLogin(presentationDelegate: ASAuthorizationControllerPresentationContextProviding) {}

    public var return_isAppleAccountValid = true
    override public func isAppleAccountValid() -> Bool {
        return_isAppleAccountValid
    }
}
