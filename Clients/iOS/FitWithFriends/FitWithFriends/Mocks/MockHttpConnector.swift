//
//  MockHttpConnector.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockHttpConnector: IHttpConnector {
    public init() {}

    public var param_url: String?
    public var param_headers: [String: String]?
    public var param_body: Encodable?
    public var param_method: HttpMethod?
    public var return_data: Decodable?
    public var return_error: Error?
    public func makeRequest<T>(url: String,
                               headers: [String : String]?,
                               body: Encodable?,
                               method: HttpMethod) async throws -> T where T : Decodable {
        param_url = url
        param_headers = headers
        param_body = body
        param_method = method

        await MockUtilities.delayOneSecond()

        if let data = return_data as? T {
            return data
        } else {
            throw return_error ?? HttpError.generic
        }
    }
}
