//
//  HttpError.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

enum HttpError: LocalizedError, CustomStringConvertible, ErrorWithDetails {
    case invalidUrl(url: String)
    case serverError(code: Int, details: FWFErrorDetails?)
    case clientError(code: Int, details: FWFErrorDetails?)
    case generic

    var errorDescription: String? {
        return description
    }

    var errorDetails: FWFErrorDetails? {
        switch self {
        case let .clientError(_, details):
            return details
        case let .serverError(_, details):
            return details
        default:
            return nil
        }
    }

    var description: String {
        switch self {
        case let .invalidUrl(url: url):
            return "Invalid url: \(url)"
        case let .serverError(code, _):
            return "Server error. HTTP \(code)"
        case let .clientError(code, _):
            return "Client error: HTTP \(code)"
        default:
            return "Generic networking error"
        }
    }
}
