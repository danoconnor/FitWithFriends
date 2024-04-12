//
//  MockHttpConnector.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockHttpConnector: IHttpConnector {
    public init() {}

    public var return_data: Decodable?
    public var return_error: Error?
    public func makeRequest<T>(url: String,
                                 headers: [String : String]?,
                                 body: [String : String]?,
                                 method: HttpMethod) async throws -> T where T : Decodable {
        await MockUtilities.delayOneSecond()

        if let data = return_data as? T {
            return data
        } else {
            throw return_error ?? HttpError.generic
        }
    }
}
