//
//  ViewState.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

enum ViewOperationState: Equatable {
    case notStarted
    case inProgress
    case failed(errorMessage: String)
    case success

    var isFailed: Bool {
        switch self {
        case .failed: return true
        default: return false
        }
    }

    var errorMessage: String {
        switch self {
        case let .failed(errorMessage):
            return errorMessage
        default:
            return ""
        }
    }
}
