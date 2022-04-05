//
//  CompetitionService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class CompetitionService: ServiceBase {
    func getCompetitionOverview(competitionId: UUID) async -> Result<CompetitionOverview, Error> {
        return await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/\(competitionId.uuidString)/overview",
                                                       method: .get)
    }

    func getUsersCompetitions(userId: String) async -> Result<[UUID], Error> {
        return await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions",
                                                       method: .get)
    }

    func createCompetition(startDate: Date, endDate: Date, competitionName: String) async -> Error? {
        let dateFormatter = ISO8601DateFormatter()

        let requestBody: [String: String] = [
            "startDate": dateFormatter.string(from: startDate),
            "endDate": dateFormatter.string(from: endDate),
            "displayName": competitionName,
            "ianaTimezone": TimeZone.current.identifier
        ]

        let result: Result<EmptyResponse, Error> = await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions",
                                                                                           method: .post,
                                                                                           body: requestBody)
        return result.xtError
    }

    func joinCompetition(competitionId: UUID, competitionToken: String) async -> Error? {
        let requestBody: [String: String] = [
            "accessToken": competitionToken,
            "competitionId": competitionId.uuidString
        ]

        let result: Result<EmptyResponse, Error> = await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/join",
                                                                                           method: .post,
                                                                                           body: requestBody)
        return result.xtError
    }

    func removeUserFromCompetition(userId: String, competitionId: UUID) async -> Error? {
        let requestBody: [String: String] = [
            "competitionId": competitionId.uuidString,
            "userId": userId.description
        ]

        let result: Result<EmptyResponse, Error> = await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/leave",
                                                                                           method: .post,
                                                                                           body: requestBody)
        return result.xtError
    }

    func getCompetitionDetails(competitionId: UUID, competitionToken: String) async -> Result<CompetitionDescription, Error> {
        let requestBody: [String: String] = [
            "competitionId": competitionId.uuidString,
            "competitionAccessToken": competitionToken
        ]

        return await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/description",
                                                       method: .post,
                                                       body: requestBody)
    }

    func getCompetitionAdminDetails(competitionId: UUID) async -> Result<CompetitionAdminDetails, Error> {
        return await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/\(competitionId.uuidString)/adminDetail",
                                                       method: .get)
    }
}
