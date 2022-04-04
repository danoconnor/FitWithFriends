//
//  CompetitionOverview.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class CompetitionOverview: IdentifiableBase, Codable {
    // MARK: Codable

    let competitionId: UUID
    let competitionName: String
    let competitionStart: Date
    let competitionEnd: Date
    let currentResults: [UserCompetitionPoints]

    /// If the current user is the admin of the competition
    let isUserAdmin: Bool

    enum CodingKeys: String, CodingKey {
        case competitionId
        case competitionName
        case competitionStart
        case competitionEnd
        case currentResults
        case isUserAdmin
    }

    /// This init is used for testing and mock data. Production code will decode the entity from JSON
    init(id: UUID = UUID(), name: String = "Test Competition", start: Date = Date(), end: Date = Date(), currentResults: [UserCompetitionPoints] = [], isUserAdmin: Bool = false) {
        competitionId = id
        competitionName = name
        competitionStart = start
        competitionEnd = end
        self.currentResults = currentResults
        self.isUserAdmin = isUserAdmin
    }
}

class UserCompetitionPoints: Codable, Identifiable {
    // MARK: Codable

    let userId: String
    let firstName: String
    let lastName: String
    let totalPoints: Double
    let pointsToday: Double?

    var displayName: String {
        firstName + " " + lastName
    }

    enum CodingKeys: String, CodingKey {
        case userId
        case firstName
        case lastName
        case totalPoints = "activityPoints"
        case pointsToday = "dailyPoints"
    }

    // MARK: Identifiable

    let id = UUID()

    /// This init is used for testing and mock data. Production code will decode the entity from JSON
    init(userId: String = "user_id", firstName: String = "Test", lastName: String = "User", total: Double = 0, today: Double = 0) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        totalPoints = total
        pointsToday = today
    }
}
