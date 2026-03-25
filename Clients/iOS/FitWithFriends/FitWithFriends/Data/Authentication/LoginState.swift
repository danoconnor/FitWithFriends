//
//  LoginState.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/4/21.
//

import Foundation

public enum LoginState: Equatable {
    case notLoggedIn(Error?)
    case needUserInfo
    case inProgress
    case loggedIn

    public static func == (lhs: LoginState, rhs: LoginState) -> Bool {
        switch (lhs, rhs) {
        case (.notLoggedIn(let lhsError), .notLoggedIn(let rhsError)):
            return (lhsError as NSError?) == (rhsError as NSError?)
        case (.needUserInfo, .needUserInfo):
            return true
        case (.inProgress, .inProgress):
            return true
        case (.loggedIn, .loggedIn):
            return true
        default:
            return false
        }
    }
}
