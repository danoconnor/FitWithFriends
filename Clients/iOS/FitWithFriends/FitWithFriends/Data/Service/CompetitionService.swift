//
//  CompetitionService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class CompetitionService: ServiceBase {
    func getCompetitionOverview(competitionId: UInt, completion: @escaping (Result<CompetitionOverview, Error>) -> Void) {
        makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/\(competitionId)/overview",
                                          method: .get,
                                          completion: completion)
    }

    func getUsersCompetitions(userId: UInt, completion: @escaping (Result<[UInt], Error>) -> Void) {
        makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions",
                                          method: .get,
                                          completion: completion)
    }
}
