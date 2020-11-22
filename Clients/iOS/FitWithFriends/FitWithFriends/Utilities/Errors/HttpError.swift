//
//  HttpError.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

enum HttpError: LocalizedError {
    case invalidUrl(url: String)
    case generic

    var errorDescription: String? {
        switch self {
        case let .invalidUrl(url: url):
            return "Invalid url: \(url)"
        default:
            return "Generic networking error"
        }
    }
}
