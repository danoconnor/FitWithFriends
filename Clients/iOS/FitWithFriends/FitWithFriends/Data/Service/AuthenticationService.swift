//
//  AuthenticationService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

public class AuthenticationService: ServiceBase, IAuthenticationService {
    /// Gets a token using the idToken provided by Sign-In with Apple
    public func getTokenFromAppleId(userId: String, idToken: String, authorizationCode: String) async -> Result<Token, Error> {
        let requestBody: [String: String] = [
            "userId": userId,
            "idToken": idToken,
            "authorizationCode": authorizationCode,
            RequestConstants.Body.grantType: RequestConstants.Body.appleIdTokenGrant
        ]

        return await makeRequestWithClientAuthentication(url: "\(SecretConstants.serviceBaseUrl)/oauth/token",
                                                         method: .post,
                                                         body: requestBody)
    }
}
