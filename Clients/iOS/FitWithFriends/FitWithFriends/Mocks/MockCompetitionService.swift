//
//  MockCompetitionService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockCompetitionService: CompetitionService {
    var return_error: Error?

    init() {
        super.init(httpConnector: MockHttpConnector(), tokenManager: MockTokenManager())
    }

    var return_competitionOverview: CompetitionOverview?
    override func getCompetitionOverview(competitionId: UInt) async -> Result<CompetitionOverview, Error> {
        await MockUtilities.delayOneSecond()

        if let competitionOverview = return_competitionOverview {
            return .success(competitionOverview)
        } else {
            return .failure(return_error ?? HttpError.generic)
        }
    }

    var return_usersCompetitions: [UInt]?
    override func getUsersCompetitions(userId: UInt) async -> Result<[UInt], Error> {
        await MockUtilities.delayOneSecond()

        if let competitions = return_usersCompetitions {
            return .success(competitions)
        } else {
            return .failure(return_error ?? HttpError.generic)
        }
    }
}
