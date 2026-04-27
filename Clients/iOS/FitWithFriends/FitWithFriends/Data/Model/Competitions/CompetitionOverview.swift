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
        case scoringRules
        case scoringUnit
    }

    let competitionId: UUID
    let competitionName: String
    let currentResults: [UserCompetitionPoints]
    let competitionStart: Date
    let competitionEnd: Date
    let competitionState: CompetitionState
    let isPublic: Bool

    /// Scoring rule configuration for the competition. Legacy competitions (pre-feature) send
    /// no value; treat as the default rings rule so UI keeps rendering.
    let scoringRules: ScoringRules

    /// Unit string the leaderboard should use ("points", "meters", "steps", etc.). Always
    /// present on responses from a current server; falls back to the rule-derived unit otherwise.
    let scoringUnit: ScoringUnit

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
    init(id: UUID = UUID(), name: String = "Test Competition", start: Date = Date(), end: Date = Date(), currentResults: [UserCompetitionPoints] = [], isUserAdmin: Bool = false, competitionState: CompetitionState = .notStartedOrActive, isPublic: Bool = false, scoringRules: ScoringRules = .default, scoringUnit: ScoringUnit? = nil) {
        competitionId = id
        competitionName = name
        competitionStart = start
        competitionEnd = end
        self.currentResults = currentResults
        self.isUserAdmin = isUserAdmin
        self.competitionState = competitionState
        self.isPublic = isPublic
        self.scoringRules = scoringRules
        self.scoringUnit = scoringUnit ?? ScoringUnit.derive(from: scoringRules)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        competitionId = try container.decode(UUID.self, forKey: .competitionId)
        competitionName = try container.decode(String.self, forKey: .competitionName)
        currentResults = try container.decode([UserCompetitionPoints].self, forKey: .currentResults)
        competitionStart = try container.decode(Date.self, forKey: .competitionStart)
        competitionEnd = try container.decode(Date.self, forKey: .competitionEnd)
        competitionState = try container.decode(CompetitionState.self, forKey: .competitionState)
        isPublic = try container.decode(Bool.self, forKey: .isPublic)
        isUserAdmin = try container.decode(Bool.self, forKey: .isUserAdmin)

        let rules = (try? container.decodeIfPresent(ScoringRules.self, forKey: .scoringRules)) ?? .default
        scoringRules = rules
        scoringUnit = (try? container.decodeIfPresent(ScoringUnit.self, forKey: .scoringUnit)) ?? ScoringUnit.derive(from: rules)
        super.init()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(competitionId, forKey: .competitionId)
        try container.encode(competitionName, forKey: .competitionName)
        try container.encode(currentResults, forKey: .currentResults)
        try container.encode(competitionStart, forKey: .competitionStart)
        try container.encode(competitionEnd, forKey: .competitionEnd)
        try container.encode(competitionState, forKey: .competitionState)
        try container.encode(isPublic, forKey: .isPublic)
        try container.encode(isUserAdmin, forKey: .isUserAdmin)
        try container.encode(scoringRules, forKey: .scoringRules)
        try container.encode(scoringUnit, forKey: .scoringUnit)
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
