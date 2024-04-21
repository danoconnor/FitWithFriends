//
//  LoginState.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/4/21.
//

import Foundation

public enum LoginState {
    case notLoggedIn(Error?)
    case inProgress
    case loggedIn
}
