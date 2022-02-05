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

    /// This init is used for testing and mock data. Production code will decode the entity from JSON
    init(id: UInt = 0, name: String = "Test Competition", start: Date = Date(), end: Date = Date(), currentResults: [UserCompetitionPoints] = []) {
        competitionId = id
        competitionName = name
        competitionStart = start
        competitionEnd = end
        self.currentResults = currentResults
    }
}

class UserCompetitionPoints: Codable, Identifiable {
    // MARK: Codable

    let userId: UInt
    let displayName: String
    let totalPoints: Double
    let pointsToday: Double?

    enum CodingKeys: String, CodingKey {
        case userId
        case displayName
        case totalPoints
        case pointsToday
    }

    // MARK: Identifiable

    let id = UUID()

    /// This init is used for testing and mock data. Production code will decode the entity from JSON
    init(userId: UInt = 0, name: String = "Test user", total: Double = 0, today: Double = 0) {
        self.userId = userId
        displayName = name
        totalPoints = total
        pointsToday = today
    }
}
