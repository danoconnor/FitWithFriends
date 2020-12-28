//
//  AuthenticationService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class AuthenticationService: ServiceBase {
    /// Gets a token using the user's credentials
    func getToken(username: String, password: String, completion: @escaping (Result<Token, Error>) -> Void) {
        let requestBody: [String: String] = [
            "username": username,
            "password": password,
            RequestConstants.Body.grantType: RequestConstants.Body.passwordGrant
        ]

        makeRequestWithClientAuthentication(url: "\(SecretConstants.serviceBaseUrl)/oauth/token",
                                            method: .post,
                                            body: requestBody,
                                            completion: completion)
    }
}
