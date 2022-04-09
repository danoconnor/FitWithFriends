//
//  CompetitionOverview.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class CompetitionOverview: IdentifiableBase, Codable, Comparable {
    let competitionId: UUID
    let competitionName: String
    let competitionStart: Date
    let competitionEnd: Date
    let currentResults: [UserCompetitionPoints]

    /// If the current user is the admin of the competition
    let isUserAdmin: Bool

    var hasCompetitionStarted: Bool {
        return Date() > competitionStart
    }

    var hasCompetitionEnded: Bool {
        return Date() > competitionEnd
    }

    var isCompetitionActive: Bool {
        return hasCompetitionStarted && !hasCompetitionEnded
    }

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

    // MARK: Comparable

    static func == (lhs: CompetitionOverview, rhs: CompetitionOverview) -> Bool {
        return lhs.competitionId == rhs.competitionId
    }

    static func < (lhs: CompetitionOverview, rhs: CompetitionOverview) -> Bool {
        // Order active competitions before non-active competitions
        if lhs.isCompetitionActive != rhs.isCompetitionActive {
            return lhs.isCompetitionActive
        }

        // If the two competitions are not active,
        // then put upcoming competitions before past competitions
        if !lhs.isCompetitionActive,
           (lhs.hasCompetitionStarted != rhs.hasCompetitionStarted || lhs.hasCompetitionEnded != lhs.hasCompetitionEnded){
            return !lhs.hasCompetitionStarted
        }

        // By this point, both competitions are in the same state (not started, active, completed)

        // If the competitions haven't started yet, then put the one that will start the soonest first
        if (!lhs.hasCompetitionStarted) {
            return lhs.competitionStart > rhs.competitionStart
        }

        // If the competitions have ended, put the one that ended most recently first
        if (lhs.hasCompetitionEnded) {
            return lhs.competitionEnd < rhs.competitionEnd
        }

        // Both competitions are active, then put the one that will finish the soonest first
        if (lhs.competitionEnd != rhs.competitionEnd) {
            return lhs.competitionEnd > rhs.competitionEnd
        }

        // If both competitions are active and end on the same date, then put the longest running competition first
        if (lhs.competitionStart != rhs.competitionStart) {
            return lhs.competitionStart < rhs.competitionStart
        }

        // If both competitions are active and start and end at the same time, just order by the UUID
        return lhs.competitionId.uuidString < rhs.competitionId.uuidString
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
