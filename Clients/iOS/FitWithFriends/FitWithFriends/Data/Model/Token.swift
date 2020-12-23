//
//  Token.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

class Token: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: UInt

    var isAccessTokenExpired: Bool {
        // TODO: fix 
        // return access_token_expires_on < Date()
        return false
    }
}
