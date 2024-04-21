//
//  CompetitionOverview.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

public class CompetitionOverview: IdentifiableBase, Codable, Comparable {
    enum CodingKeys: String, CodingKey {
        case competitionId
        case competitionName
        case competitionStart
        case competitionEnd
        case currentResults
        case isUserAdmin
        case isCompetitionProcessingResults
    }

    let competitionId: UUID
    let competitionName: String
    let currentResults: [UserCompetitionPoints]
    let competitionStart: Date
    let competitionEnd: Date
    let isCompetitionProcessingResults: Bool

    var startDate: Date {
        competitionStart.convertFromUTCToCurrentTimezone() ?? competitionStart
    }

    var endDate: Date {
        competitionEnd.convertFromUTCToCurrentTimezone() ?? competitionEnd
    }

    /// If the current user is the admin of the competition
    let isUserAdmin: Bool

    var hasCompetitionStarted: Bool {
        return Date() > startDate
    }

    var hasCompetitionEnded: Bool {
        return Date() > endDate
    }

    var isCompetitionActive: Bool {
        return hasCompetitionStarted && !hasCompetitionEnded
    }

    /// This init is used for testing and mock data. Production code will decode the entity from JSON
    init(id: UUID = UUID(), name: String = "Test Competition", start: Date = Date(), end: Date = Date(), currentResults: [UserCompetitionPoints] = [], isUserAdmin: Bool = false, isCompetitionProcessingResults: Bool = false) {
        competitionId = id
        competitionName = name
        competitionStart = start
        competitionEnd = end
        self.currentResults = currentResults
        self.isUserAdmin = isUserAdmin
        self.isCompetitionProcessingResults = isCompetitionProcessingResults
    }

    // MARK: Comparable

    public static func == (lhs: CompetitionOverview, rhs: CompetitionOverview) -> Bool {
        return lhs.competitionId == rhs.competitionId
    }

    public static func < (lhs: CompetitionOverview, rhs: CompetitionOverview) -> Bool {
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
            return lhs.startDate > rhs.startDate
        }

        // If the competitions have ended, put the one that ended most recently first
        if (lhs.hasCompetitionEnded) {
            return lhs.endDate > rhs.endDate
        }

        // Both competitions are active, then put the one that will finish the soonest first
        if (lhs.endDate != rhs.endDate) {
            return lhs.endDate > rhs.endDate
        }

        // If both competitions are active and end on the same date, then put the longest running competition first
        if (lhs.startDate != rhs.startDate) {
            return lhs.startDate < rhs.startDate
        }

        // If both competitions are active and start and end at the same time, just order by the UUID
        return lhs.competitionId.uuidString < rhs.competitionId.uuidString
    }
}

public class UserCompetitionPoints: IdentifiableBase, Codable, Comparable {
    enum CodingKeys: String, CodingKey {
        case userId
        case firstName
        case lastName
        case totalPoints = "activityPoints"
        case pointsToday = "dailyPoints"
    }

    let userId: String
    let firstName: String
    let lastName: String
    let totalPoints: Double?
    let pointsToday: Double?

    var displayName: String {
        firstName + " " + lastName
    }

    /// This init is used for testing and mock data. Production code will decode the entity from JSON
    public init(userId: String = "user_id", firstName: String = "Test", lastName: String = "User", total: Double = 0, today: Double = 0) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        totalPoints = total
        pointsToday = today
    }

    public static func == (lhs: UserCompetitionPoints, rhs: UserCompetitionPoints) -> Bool {
        return lhs.userId == rhs.userId
    }

    public static func < (lhs: UserCompetitionPoints, rhs: UserCompetitionPoints) -> Bool {
        let lhsPoints = lhs.totalPoints ?? 0
        let rhsPoints = rhs.totalPoints ?? 0

        // If one or both sides have points, order by highest points first
        if lhs.totalPoints != nil || rhs.totalPoints != nil {
            if lhsPoints != rhsPoints {
                return lhsPoints > rhsPoints
            }

            // If total points are equal, use points today as a tiebreaker
            if lhs.pointsToday != rhs.pointsToday {
                return (lhs.pointsToday ?? 0) > (rhs.pointsToday ?? 0)
            }
        }

        // Default to ordering by name if there are no points,
        // or the total points and points today are both equal
        return lhs.displayName > rhs.displayName
    }
}
