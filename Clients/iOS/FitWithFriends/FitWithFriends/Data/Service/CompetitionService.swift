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

    func createCompetition(startDate: Date, endDate: Date, competitionName: String, completion: @escaping (Result<EmptyReponse, Error>) -> Void) {
        let dateFormatter = ISO8601DateFormatter()

        let requestBody: [String: String] = [
            "startDate": dateFormatter.string(from: startDate),
            "endDate": dateFormatter.string(from: endDate),
            "displayName": competitionName
        ]

        makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions",
                                          method: .post,
                                          body: requestBody,
                                          completion: completion)
    }
}
