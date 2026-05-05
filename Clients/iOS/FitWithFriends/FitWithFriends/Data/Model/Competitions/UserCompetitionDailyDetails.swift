//
//  UserCompetitionDailyDetails.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/9/26.
//

import Foundation

public class UserCompetitionDailyDetails: IdentifiableBase, Codable {
    enum CodingKeys: String, CodingKey {
        case userId
        case firstName
        case lastName
        case competitionId
        case dailySummaries
        case scoringUnit
    }

    let userId: String
    let firstName: String
    let lastName: String
    let competitionId: UUID
    let dailySummaries: [DailySummary]
    /// Unit for the rule the competition is scored with. Falls back to points when the server
    /// doesn't supply a value (older server response).
    let scoringUnit: ScoringUnit

    var displayName: String {
        firstName + " " + lastName
    }

    init(userId: String = "user_id",
         firstName: String = "Test",
         lastName: String = "User",
         competitionId: UUID = UUID(),
         dailySummaries: [DailySummary] = [],
         scoringUnit: ScoringUnit = .points) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.competitionId = competitionId
        self.dailySummaries = dailySummaries
        self.scoringUnit = scoringUnit
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        competitionId = try container.decode(UUID.self, forKey: .competitionId)
        dailySummaries = try container.decode([DailySummary].self, forKey: .dailySummaries)
        scoringUnit = try container.decodeIfPresent(ScoringUnit.self, forKey: .scoringUnit) ?? .points
        super.init()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(competitionId, forKey: .competitionId)
        try container.encode(dailySummaries, forKey: .dailySummaries)
        try container.encode(scoringUnit, forKey: .scoringUnit)
    }
}
