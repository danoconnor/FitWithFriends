//
//  AccessToken.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

class Token: Decodable {
    let access_token: String
    let access_token_expires_on: Date
    let refresh_token: String
    let refresh_token_expires_on: Date

    var isAccessTokenExpired: Bool {
        return access_token_expires_on < Date()
    }

    var isRefreshTokenExpired: Bool {
        return refresh_token_expires_on < Date()
    }
}
