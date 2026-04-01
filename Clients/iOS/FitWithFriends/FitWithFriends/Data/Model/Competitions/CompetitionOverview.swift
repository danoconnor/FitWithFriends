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
        case competitionState
        case isPublic
    }

    let competitionId: UUID
    let competitionName: String
    let currentResults: [UserCompetitionPoints]
    let competitionStart: Date
    let competitionEnd: Date
    let competitionState: CompetitionState
    let isPublic: Bool

    /// If the current user is the admin of the competition
    let isUserAdmin: Bool

    var startDate: Date {
        competitionStart.convertFromUTCToCurrentTimezone() ?? competitionStart
    }

    var endDate: Date {
        competitionEnd.convertFromUTCToCurrentTimezone() ?? competitionEnd
    }

    var isCompetitionProcessingResults: Bool {
        return competitionState == .processingResults
    }

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
    init(id: UUID = UUID(), name: String = "Test Competition", start: Date = Date(), end: Date = Date(), currentResults: [UserCompetitionPoints] = [], isUserAdmin: Bool = false, competitionState: CompetitionState = .notStartedOrActive, isPublic: Bool = false) {
        competitionId = id
        competitionName = name
        competitionStart = start
        competitionEnd = end
        self.currentResults = currentResults
        self.isUserAdmin = isUserAdmin
        self.competitionState = competitionState
        self.isPublic = isPublic
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
