//
//  UserService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class UserService: ServiceBase {
    /// Creates a new user with the given credentials/user info. Will return an error if the username already exists
    func createUser(username: String, password: String, displayName: String) async -> Result<User, Error> {
        let requestBody: [String: String] = [
            "username": username,
            "password": password,
            "displayName": displayName
        ]

        return await makeRequestWithClientAuthentication(url: "\(SecretConstants.serviceBaseUrl)/users",
                                                         method: .post,
                                                         body: requestBody)
    }
}
