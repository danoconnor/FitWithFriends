//
//  CompetitionService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class CompetitionService: ServiceBase {
    func getCompetitionOverview(competitionId: UInt) async -> Result<CompetitionOverview, Error> {
        return await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/\(competitionId)/overview",
                                                       method: .get)
    }

    func getUsersCompetitions(userId: UInt) async -> Result<[UInt], Error> {
        return await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions",
                                                       method: .get)
    }

    func createCompetition(startDate: Date, endDate: Date, competitionName: String) async -> Error? {
        let dateFormatter = ISO8601DateFormatter()

        let requestBody: [String: String] = [
            "startDate": dateFormatter.string(from: startDate),
            "endDate": dateFormatter.string(from: endDate),
            "displayName": competitionName
        ]

        let result: Result<EmptyResponse, Error> = await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions",
                                                                                           method: .post,
                                                                                           body: requestBody)
        return result.xtError
    }

    func joinCompetition(competitionToken: String) async -> Error? {
        let requestBody: [String: String] = [
            "accessToken": competitionToken
        ]

        let result: Result<EmptyResponse, Error> = await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/join",
                                                                                           method: .post,
                                                                                           body: requestBody)
        return result.xtError
    }

    func removeUserFromCompetition(userId: UInt, competitionId: UInt) async -> Error? {
        let requestBody: [String: String] = [
            "competitionId": competitionId.description,
            "userId": userId.description
        ]

        let result: Result<EmptyResponse, Error> = await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/leave",
                                                                                           method: .post,
                                                                                           body: requestBody)
        return result.xtError
    }
}
