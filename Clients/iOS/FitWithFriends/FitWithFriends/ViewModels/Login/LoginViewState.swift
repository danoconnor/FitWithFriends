//
//  LoginViewState.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 8/2/25.
//

public enum LoginViewState: Equatable {
    case notStarted
    case inProgress
    case needUserInfo
    case failed(errorMessage: String)
    case success

    public var isFailed: Bool {
        switch self {
        case .failed: return true
        default: return false
        }
    }

    public var errorMessage: String {
        switch self {
        case let .failed(errorMessage):
            return errorMessage
        default:
            return ""
        }
    }
}
