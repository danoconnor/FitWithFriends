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
    override func makeRequest<T>(url: String,
                                 headers: [String : String]? = nil,
                                 body: [String : String]? = nil,
                                 method: HttpMethod) async -> Result<T, Error> where T : Decodable {
        await MockUtilities.delayOneSecond()

        if let data = return_data as? T {
            return .success(data)
        } else {
            return .failure(return_error ?? HttpError.generic)
        }
    }
}
