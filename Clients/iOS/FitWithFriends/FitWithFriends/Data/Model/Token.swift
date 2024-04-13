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
    public var refreshTokenExpiry: Date?
    public let userId: String

    public var isAccessTokenExpired: Bool {
        return accessTokenExpiry < Date()
    }

    public var isRefreshTokenExpired: Bool {
        guard let refreshTokenExpiry = refreshTokenExpiry else {
            // If we don't have a refresh token, then we need to get one
            return true
        }

        return refreshTokenExpiry < Date()
    }

    /// Used by unit tests
    init(accessToken: String, accessTokenExpiry: Date, refreshToken: String? = nil, refreshTokenExpiry: Date? = nil, userId: String) {
        self.accessToken = accessToken
        self.accessTokenExpiry = accessTokenExpiry
        self.refreshToken = refreshToken
        self.refreshTokenExpiry = refreshTokenExpiry
        self.userId = userId
    }
}
