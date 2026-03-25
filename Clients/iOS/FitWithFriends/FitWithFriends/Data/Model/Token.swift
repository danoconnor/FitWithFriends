//
//  Token.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

public class Token: Codable {
    public let accessToken: String
    public let accessTokenExpiry: Date
    public var refreshToken: String?
    public let userId: String

    public var isAccessTokenExpired: Bool {
        return accessTokenExpiry < Date()
    }

    /// Used by unit tests
    init(accessToken: String, accessTokenExpiry: Date, refreshToken: String? = nil, userId: String) {
        self.accessToken = accessToken
        self.accessTokenExpiry = accessTokenExpiry
        self.refreshToken = refreshToken
        self.userId = userId
    }
}

extension Token: Equatable {
    public static func == (lhs: Token, rhs: Token) -> Bool {
        return lhs.accessToken == rhs.accessToken &&
               lhs.accessTokenExpiry == rhs.accessTokenExpiry &&
               lhs.refreshToken == rhs.refreshToken &&
               lhs.userId == rhs.userId
    }
}
