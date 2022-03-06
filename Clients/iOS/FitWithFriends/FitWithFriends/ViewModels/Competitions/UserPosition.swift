//
//  UserPosition.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/5/22.
//

import Foundation

struct UserPosition: Identifiable {
    let userCompetitionPoints: UserCompetitionPoints

    /// The position to display to the user, starting from 1 (not 0)
    let position: UInt

    let id = UUID()
}
