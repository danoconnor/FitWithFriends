//
//  MockCompetitionManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockCompetitionManager: CompetitionManager {
    var return_error: Error?

    var return_competitionOverviews: [UInt: CompetitionOverview] = [:]
    override var competitionOverviews: [UInt : CompetitionOverview] {
        return_competitionOverviews
    }

    init() {
        super.init(authenticationManager: MockAuthenticationManager(), competitionService: MockCompetitionService())

        // Default to having a competition
        let results = [
            UserCompetitionPoints(userId: 1, name: "Test user 1", total: 300, today: 125),
            UserCompetitionPoints(userId: 2, name: "Test user 2", total: 425, today: 75),
            UserCompetitionPoints(userId: 3, name: "Test user 3", total: 100, today: 0)
        ]
        return_competitionOverviews = [
            0: CompetitionOverview(start: Date(), end: Date().addingTimeInterval(TimeInterval.xtDays(7)), currentResults: results)
        ]
    }

    override func createCompetition(startDate: Date, endDate: Date, competitionName: String, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            completion(self?.return_error)
        }
    }
}
