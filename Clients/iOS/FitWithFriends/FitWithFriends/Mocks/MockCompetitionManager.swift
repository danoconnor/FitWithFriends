//
//  MockCompetitionManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockCompetitionManager: CompetitionManager {
    var return_error: Error?

    var return_competitionOverviews: [UUID: CompetitionOverview] = [:]
    override var competitionOverviews: [UUID : CompetitionOverview] {
        return_competitionOverviews
    }

    init() {
        super.init(authenticationManager: MockAuthenticationManager(), competitionService: MockCompetitionService())

        // Default to having a competition
        let results = [
            UserCompetitionPoints(userId: "user_1", firstName: "Test", lastName: "User 1", total: 300, today: 125),
            UserCompetitionPoints(userId: "user_2", firstName: "Test", lastName: "User 2", total: 425, today: 75),
            UserCompetitionPoints(userId: "user_3", firstName: "Test", lastName: "User 3", total: 100, today: 0)
        ]
        
        return_competitionOverviews = [
            UUID(): CompetitionOverview(start: Date(), end: Date().addingTimeInterval(TimeInterval.xtDays(7)), currentResults: results),
            UUID(): CompetitionOverview(start: Date(), end: Date().addingTimeInterval(TimeInterval.xtDays(7)), currentResults: results),
            UUID(): CompetitionOverview(start: Date(), end: Date().addingTimeInterval(TimeInterval.xtDays(7)), currentResults: results),
        ]
    }

    override func createCompetition(startDate: Date, endDate: Date, competitionName: String) async -> Error? {
        await MockUtilities.delayOneSecond()
        return return_error
    }
}
