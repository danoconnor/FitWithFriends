//
//  CompetitionService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

public class CompetitionService: ServiceBase, ICompetitionService {
    public func getCompetitionOverview(competitionId: UUID) async -> Result<CompetitionOverview, Error> {
        // Need to query using the user's current timezone so we get accurate information on whether the competition is active or not
        let ianaTimezone = TimeZone.current.identifier

        return await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/\(competitionId.uuidString)/overview?timezone=\(ianaTimezone)",
                                                       method: .get)
    }

    public func getUsersCompetitions(userId: String) async -> Result<[UUID], Error> {
        return await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions",
                                                       method: .get)
    }

    public func createCompetition(startDate: Date, endDate: Date, competitionName: String) async -> Error? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = Calendar.current.timeZone
        dateFormatter.formatOptions = .withFullDate

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

    public func joinCompetition(competitionId: UUID, competitionToken: String) async -> Error? {
        let requestBody: [String: String] = [
            "accessToken": competitionToken,
            "competitionId": competitionId.uuidString
        ]

        let result: Result<EmptyResponse, Error> = await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/join",
                                                                                           method: .post,
                                                                                           body: requestBody)
        return result.xtError
    }

    public func removeUserFromCompetition(userId: String, competitionId: UUID) async -> Error? {
        let requestBody: [String: String] = [
            "competitionId": competitionId.uuidString,
            "userId": userId.description
        ]

        let result: Result<EmptyResponse, Error> = await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/leave",
                                                                                           method: .post,
                                                                                           body: requestBody)
        return result.xtError
    }

    public func getCompetitionDescription(competitionId: UUID, competitionToken: String) async -> Result<CompetitionDescription, Error> {
        let requestBody: [String: String] = [
            "competitionId": competitionId.uuidString,
            "competitionAccessToken": competitionToken
        ]

        return await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/description",
                                                       method: .post,
                                                       body: requestBody)
    }

    /// The user must be the admin of the competition, otherwise the request will be rejected
    public func getCompetitionAdminDetails(competitionId: UUID) async -> Result<CompetitionAdminDetails, Error> {
        return await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/\(competitionId.uuidString)/adminDetail",
                                                       method: .get)
    }

    /// The user must be the admin of the competition, otherwise the request will be rejected
    public func deleteCompetition(competitionId: UUID) async -> Error? {
        let requestBody: [String: String] = [
            "competitionId": competitionId.uuidString
        ]

        let result: Result<EmptyResponse, Error> = await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/competitions/delete",
                                                                                           method: .post,
                                                                                           body: requestBody)

        return result.xtError
    }
}
