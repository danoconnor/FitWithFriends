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
    let refreshToken: String
    let refreshTokenExpiry: Date
    let userId: String

    var isAccessTokenExpired: Bool {
        return accessTokenExpiry < Date()
    }

    var isRefreshTokenExpired: Bool {
        return refreshTokenExpiry < Date()
    }
}
