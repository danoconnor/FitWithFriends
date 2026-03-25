//
//  LoginSheetState.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 8/3/25.
//

/// The various sheets that may be displayed over the login screen
public enum LoginSheet: Identifiable {
    case none
    case firstLaunchWelcomeView
    case userInputView

    /// Needed for Identifiable, which is needed to work with SwiftUI .sheet(item:)
    public var id: String {
        switch self {
        case .none:
            return "none"
        case .firstLaunchWelcomeView:
            return "firstLaunchWelcomeView"
        case .userInputView:
            return "userInputView"
        }
    }
}
