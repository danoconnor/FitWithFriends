//
//  UserPosition.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/5/22.
//

import Foundation

struct UserPosition: Identifiable {
    let id = UUID()

    let userCompetitionPoints: UserCompetitionPoints

    /// The position to display to the user, starting from 1 (not 0)
    let position: UInt

    /// Whether we should show the user's position number
    /// If the user doesn't have any points yet, then we just want to display their name
    var shouldShowPosition: Bool {
        return userCompetitionPoints.totalPoints != nil
    }
}
