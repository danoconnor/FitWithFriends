//
//  MockHttpConnector.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockHttpConnector: HttpConnector {
    var return_data: Decodable?
    var return_error: Error?
    override func makeRequest<T: Decodable>(url: String, headers: [String : String]? = nil, body: [String : String]? = nil, method: HttpMethod, completion: @escaping (Result<T, Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            if let data = self?.return_data as? T {
                completion(.success(data))
            } else {
                completion(.failure(self?.return_error ?? HttpError.generic))
            }
        }
    }
}
