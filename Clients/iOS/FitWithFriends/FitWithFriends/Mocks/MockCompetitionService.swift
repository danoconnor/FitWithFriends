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
    override func getCompetitionOverview(competitionId: UUID) async -> Result<CompetitionOverview, Error> {
        await MockUtilities.delayOneSecond()

        if let competitionOverview = return_competitionOverview {
            return .success(competitionOverview)
        } else {
            return .failure(return_error ?? HttpError.generic)
        }
    }

    var return_usersCompetitions: [UUID]?
    override func getUsersCompetitions(userId: String) async -> Result<[UUID], Error> {
        await MockUtilities.delayOneSecond()

        if let competitions = return_usersCompetitions {
            return .success(competitions)
        } else {
            return .failure(return_error ?? HttpError.generic)
        }
    }
}
