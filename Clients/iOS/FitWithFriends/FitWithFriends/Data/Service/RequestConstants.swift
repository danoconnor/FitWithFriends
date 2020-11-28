//
//  RequestConstants.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import Foundation

struct RequestConstants {
    struct Headers {
        static let authorization = "Authorization"
    }

    struct Body {
        static let clientId = "client_id"
        static let clientSecret = "client_secret"

        static let grantType = "grant_type"
        static let passwordGrant = "password"
        static let refreshTokenGrant = "refresh_token"

        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
    }
}
