//
//  TokenError.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

enum TokenError: Error {
    case expired(token: Token)
    case notFound
}
