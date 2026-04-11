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
    }

    let userId: String
    let firstName: String
    let lastName: String
    let competitionId: UUID
    let dailySummaries: [DailySummary]

    var displayName: String {
        firstName + " " + lastName
    }

    init(userId: String = "user_id",
         firstName: String = "Test",
         lastName: String = "User",
         competitionId: UUID = UUID(),
         dailySummaries: [DailySummary] = []) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.competitionId = competitionId
        self.dailySummaries = dailySummaries
    }
}
