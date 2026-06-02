//
//  UserService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

public class UserService: ServiceBase, IUserService {
    public func deleteAccount() async throws {
        let url = "\(serverEnvironmentManager.baseUrl)/users/me"
        let _: EmptyResponse = try await makeRequestWithUserAuthentication(url: url, method: .delete)
    }

    public func reportTimezone(_ timezone: String) async throws {
        let url = "\(serverEnvironmentManager.baseUrl)/users/timezone"
        let _: EmptyResponse = try await makeRequestWithUserAuthentication(url: url,
                                                                           method: .post,
                                                                           body: ["timezone": timezone])
    }

    /// Creates a new user with the given credentials/user info. Will return an error if the username already exists
    public func createUser(firstName: String,
                    lastName: String,
                    userId: String,
                    idToken: String,
                    authorizationCode: String) async throws {
        let requestBody: [String: String] = [
            "firstName": firstName,
            "lastName": lastName,
            "userId": userId,
            "idToken": idToken,
            "authorizationCode": authorizationCode
        ]

        let url = "\(serverEnvironmentManager.baseUrl)/users/userFromAppleID"
        let _: EmptyResponse = try await makeRequestWithClientAuthentication(url: url,
                                                                             method: .post,
                                                                             body: requestBody)
    }
}
