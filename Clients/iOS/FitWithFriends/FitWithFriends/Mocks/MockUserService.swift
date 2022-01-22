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
    override func createUser(username: String, password: String, displayName: String, completion: @escaping (Result<User, Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            if let user = self?.return_user {
                completion(.success(user))
            } else {
                completion(.failure(self?.return_error ?? HttpError.generic))
            }
        }
    }
}
