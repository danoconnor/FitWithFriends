//
//  ITokenManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/10/24.
//

import Foundation

public protocol ITokenManager {
    func getCachedToken() throws -> Token
}
