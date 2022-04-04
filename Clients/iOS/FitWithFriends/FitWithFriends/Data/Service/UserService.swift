//
//  UserService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class UserService: ServiceBase {
    /// Creates a new user with the given credentials/user info. Will return an error if the username already exists
    func createUser(firstName: String,
                    lastName: String,
                    userId: String,
                    idToken: String,
                    authorizationCode: String) async -> Result<User, Error> {
        let requestBody: [String: String] = [
            "firstName": firstName,
            "lastName": lastName,
            "userId": userId,
            "idToken": idToken,
            "authorizationCode": authorizationCode
        ]

        return await makeRequestWithClientAuthentication(url: "\(SecretConstants.serviceBaseUrl)/users/userFromAppleID",
                                                         method: .post,
                                                         body: requestBody)
    }
}
