//
//  IUserService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/25/24.
//

import Foundation

public protocol IUserService {

    /// Create a new user from Sign In With Apple
    /// - Parameters:
    ///   - firstName: The user's first name
    ///   - lastName: The user's last name
    ///   - userId: The userId provided by Apple
    ///   - idToken: The idToken provided by Apple
    ///   - authorizationCode: The authorization code provided by Apple
    /// - Returns: Nil if the request succeeds, or a relevant error if it failed
    func createUser(firstName: String,
                    lastName: String,
                    userId: String,
                    idToken: String,
                    authorizationCode: String) async -> Error?
}
