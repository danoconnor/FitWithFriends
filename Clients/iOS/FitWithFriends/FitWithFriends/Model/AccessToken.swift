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

    var isAccessTokenExpired: Bool {
        return access_token_expires_on < Date()
    }
}
