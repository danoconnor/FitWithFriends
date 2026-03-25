//
//  AppleAuthorization.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 8/2/25.
//

import AuthenticationServices
import Foundation

/// A wrapper around the `ASAuthorizationAppleIDCredential` object
/// so we can mock it during unit tests as needed
public class AppleAuthorizationCredential {
    public let userId: String
    public let idToken: String
    public let authorizationCode: String

    /// Display Name is only provied the first time tha thte user logs in with Sign In With Apple to create the account
    public let displayName: PersonNameComponents?


    /// Create an AppleAuthorizationCredential based on the values provided by Sign In With Apple
    /// - Parameter appleIdCredential: The credential from Sign In With Apple
    /// - Throws AppleAuthenticationError if the provided credential is missing criticial data
    init(appleIdCredential: ASAuthorizationAppleIDCredential) throws {
        guard let idTokenData = appleIdCredential.identityToken,
              let idToken = String(data: idTokenData, encoding: .utf8),
              let authorizationCodeData = appleIdCredential.authorizationCode,
              let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) else {
            let error: AppleAuthenticationError = appleIdCredential.identityToken == nil ? .noTokenReturned : .noAuthorizationReturned
            throw error
        }

        self.userId = appleIdCredential.user
        self.idToken = idToken
        self.authorizationCode = authorizationCode
        self.displayName = appleIdCredential.fullName
    }

    /// Used during unit tests to mock authorization
    init(userId: String, idToken: String, authorizationCode: String, displayName: PersonNameComponents?) {
        self.userId = userId
        self.idToken = idToken
        self.authorizationCode = authorizationCode
        self.displayName = displayName
    }
}
