//
//  IHttpConnector.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/25/24.
//

import Foundation

public protocol IHttpConnector {
    func makeRequest<T: Decodable>(url: String, headers: [String: String]?, body: [String: String]?, method: HttpMethod) async throws -> T
}

// Helper extension to provide default values
extension IHttpConnector {
    public func makeRequest<T: Decodable>(url: String, method: HttpMethod) async throws -> T {
        return try await makeRequest(url: url, headers: nil, body: nil, method: method)
    }
}
