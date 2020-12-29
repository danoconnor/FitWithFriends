//
//  CompetitionOverview.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class CompetitionOverview: Codable {
    let competitionId: UInt
    let competitionName: String
    let competitionStart: Date
    let competitionEnd: Date
    let currentResults: [UserCompetitionPoints]
}

class UserCompetitionPoints: Codable {
    // The user's display name
    let displayName: String
    let workoutPoints: Double
    let activityPoints: Double
}
