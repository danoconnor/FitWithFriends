//
//  Token.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

class Token: Codable {
    let accessToken: String
    let accessTokenExpiry: Date
    var refreshToken: String?
    var refreshTokenExpiry: Date?
    let userId: String

    var isAccessTokenExpired: Bool {
        return accessTokenExpiry < Date()
    }

    var isRefreshTokenExpired: Bool {
        guard let refreshTokenExpiry = refreshTokenExpiry else {
            // If we don't have a refresh token, then we need to get one
            return true
        }

        return refreshTokenExpiry < Date()
    }
}
