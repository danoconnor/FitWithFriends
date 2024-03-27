//
//  CompetitionAdminDetails.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/21/22.
//

import Foundation

public class CompetitionAdminDetails: Codable {
    let competitionId: UUID
    let competitionAccessToken: String

    /// This init is used for testing and mock data. Production code will decode the entity from JSON
    init(competitionId: UUID = UUID(), competitionAccessToken: String = "TOKEN") {
        self.competitionId = competitionId
        self.competitionAccessToken = competitionAccessToken
    }
}
