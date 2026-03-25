//
//  ASAuthorizationAppleIDProviderWrapper.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 8/14/25.
//

import AuthenticationServices

class ASAuthorizationAppleIDProviderWrapper: IASAuthorizationAppleIDProvider {
    private let provider = ASAuthorizationAppleIDProvider()

    func createRequest() -> ASAuthorizationAppleIDRequest {
        return provider.createRequest()
    }

    func getCredentialState(forUserID userID: String, completion: @escaping (ASAuthorizationAppleIDProvider.CredentialState, Error?) -> Void) {
        provider.getCredentialState(forUserID: userID, completion: completion)
    }
}
