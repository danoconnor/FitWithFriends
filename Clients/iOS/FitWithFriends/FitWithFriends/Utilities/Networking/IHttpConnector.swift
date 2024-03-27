//
//  IHttpConnector.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/25/24.
//

import Foundation

public protocol IHttpConnector {
    func makeRequest<T: Decodable>(url: String, headers: [String: String]?, body: [String: String]?, method: HttpMethod) async -> Result<T, Error>
}

// Helper extension to provide default values
extension IHttpConnector {
    public func makeRequest<T: Decodable>(url: String, method: HttpMethod) async -> Result<T, Error> {
        return await makeRequest(url: url, headers: nil, body: nil, method: method)
    }
}
