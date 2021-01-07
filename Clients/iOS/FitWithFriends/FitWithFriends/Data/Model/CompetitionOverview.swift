//
//  CompetitionOverview.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class CompetitionOverview: Codable, Identifiable {
    // MARK: Codable

    let competitionId: UInt
    let competitionName: String
    let competitionStart: Date
    let competitionEnd: Date
    let currentResults: [UserCompetitionPoints]

    enum CodingKeys: String, CodingKey {
        case competitionId
        case competitionName
        case competitionStart
        case competitionEnd
        case currentResults
    }

    // MARK: Identifiable

    let id = UUID()
}

class UserCompetitionPoints: Codable {
    // The user's display name
    let displayName: String
    let workoutPoints: Double
    let activityPoints: Double
}
