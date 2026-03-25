//
//  AppleAuthenticationDelegate.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 8/2/25.
//

public protocol AppleAuthenticationDelegate: AnyObject {
    func authenticationCompleted(result: Result<Token, Error>)

    /// Invoked when the auth layer needs more information to create a new user
    func needUserInformation()
}
