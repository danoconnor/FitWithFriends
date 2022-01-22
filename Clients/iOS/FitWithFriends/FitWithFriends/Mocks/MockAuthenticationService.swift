//
//  MockAuthenticationService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockAuthenticationService: AuthenticationService {
    init() {
        super.init(httpConnector: MockHttpConnector(), tokenManager: MockTokenManager())
    }

    var return_token: Token?
    var return_error: Error?
    override func getToken(token: Token, completion: @escaping (Result<Token, Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }

            if let token = self.return_token {
                completion(.success(token))
            } else {
                completion(.failure(self.return_error ?? HttpError.generic))
            }
        }
    }
}
