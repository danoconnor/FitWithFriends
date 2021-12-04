//
//  HttpError.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

enum HttpError: LocalizedError, CustomStringConvertible {
    case invalidUrl(url: String)
    case serverError(code: Int)
    case clientError(code: Int)
    case generic

    var errorDescription: String? {
        return description
    }

    var description: String {
        switch self {
        case let .invalidUrl(url: url):
            return "Invalid url: \(url)"
        case let .serverError(code):
            return "Server error. HTTP \(code)"
        case let .clientError(code):
            return "Client error: HTTP \(code)"
        default:
            return "Generic networking error"
        }
    }
}
