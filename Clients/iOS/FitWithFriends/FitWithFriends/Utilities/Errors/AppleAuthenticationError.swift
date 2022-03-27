//
//  AppleAuthenticationError.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/26/22.
//

import Foundation

enum AppleAuthenticationError: LocalizedError, CustomStringConvertible {
    case noAuthorizationReturned
    case noTokenReturned
    case unexpectedCredentialType(String)

    var errorDescription: String? {
        return description
    }

    var description: String {
        switch self {
        case .noAuthorizationReturned:
            return "No authorization code returned"
        case .noTokenReturned:
            return "No token returned"
        case let .unexpectedCredentialType(credentialType):
            return "Unexpected Apple credential type. Got: \(credentialType)"
        }
    }
}
