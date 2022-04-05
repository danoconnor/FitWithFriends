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

    var return_error: Error?
    override func createUser(firstName: String, lastName: String, userId: String, idToken: String, authorizationCode: String) async -> Error? {
        await MockUtilities.delayOneSecond()

        return return_error
    }
}
