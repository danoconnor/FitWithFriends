//
//  Token.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

class Token: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: UInt
    let userId: UInt

    var isAccessTokenExpired: Bool {
        // TODO: fix 
        // return access_token_expires_on < Date()
        return false
    }
}
