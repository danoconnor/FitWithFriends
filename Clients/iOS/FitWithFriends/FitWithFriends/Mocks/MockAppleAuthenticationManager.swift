//
//  MockAppleAuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/26/22.
//

import AuthenticationServices
import Foundation

class MockAppleAuthenticationManager: AppleAuthenticationManager {
    init() {
        super.init(authenticationService: MockAuthenticationService(), keychainUtilities: MockKeychainUtilities(), userService: MockUserService())
    }

    override func beginAppleLogin(presentationDelegate: ASAuthorizationControllerPresentationContextProviding) {}

    var return_isAppleAccountValid = true
    override func isAppleAccountValid() -> Bool {
        return_isAppleAccountValid
    }
}
