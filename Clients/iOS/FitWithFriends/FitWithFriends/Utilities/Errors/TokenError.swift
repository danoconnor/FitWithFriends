//
//  TokenError.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

enum TokenError: LocalizedError, CustomStringConvertible {
    case expired(token: Token)
    case notFound

    var errorDescription: String? {
        return description
    }

    var description: String {
        switch self {
        case .expired:
            return "Expired token"
        case .notFound:
            return "Token not found"
        }
    }
}

extension TokenError: Equatable {
    static func == (lhs: TokenError, rhs: TokenError) -> Bool {
        switch (lhs, rhs) {
        case (.expired(let lhsToken), .expired(let rhsToken)):
            return lhsToken == rhsToken
        case (.notFound, .notFound):
            return true
        default:
            return false
        }
    }
}
