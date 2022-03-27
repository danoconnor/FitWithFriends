//
//  MockUserService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockUserService: UserService {
    init() {
        super.init(httpConnector: MockHttpConnector(), tokenManager: MockTokenManager())
    }

    var return_user: User?
    var return_error: Error?
    override func createUser(firstName: String, lastName: String, userId: String) async -> Result<User, Error> {
        await MockUtilities.delayOneSecond()

        if let user = return_user {
            return .success(user)
        } else {
            return .failure(return_error ?? HttpError.generic)
        }
    }
}
