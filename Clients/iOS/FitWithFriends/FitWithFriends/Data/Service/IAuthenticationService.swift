//
//  IAuthenticationService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/25/24.
//

import Foundation

public protocol IAuthenticationService {
    
    /// Gets a new access token using the refresh token
    /// - Parameter token: A token containing a valid refresh token
    /// - Returns: The new access token and refresh token, or an error
    func getToken(token: Token) async throws -> Token

    /// Convert a Sign In With Apple credential into a token for the FwF backend
    /// - Parameters:
    ///   - userId: The Apple userId
    ///   - idToken: The Apple idToken
    ///   - authorizationCode: The Apple authorization code
    /// - Returns: A token for the FwF backend
    func getTokenFromAppleId(userId: String, idToken: String, authorizationCode: String) async throws -> Token
}
