//
//  CompetitionService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

public class CompetitionService: ServiceBase, ICompetitionService {
    public func getCompetitionOverview(competitionId: UUID) async throws -> CompetitionOverview {
        // Need to query using the user's current timezone so we get accurate information on whether the competition is active or not
        let ianaTimezone = TimeZone.current.identifier

        return try await makeRequestWithUserAuthentication(url: "\(serverEnvironmentManager.baseUrl)/competitions/\(competitionId.uuidString)/overview?timezone=\(ianaTimezone)",
                                                           method: .get)
    }

    public func getUsersCompetitions(userId: String) async throws -> [UUID] {
        return try await makeRequestWithUserAuthentication(url: "\(serverEnvironmentManager.baseUrl)/competitions",
                                                           method: .get)
    }

    public func createCompetition(startDate: Date, endDate: Date, competitionName: String) async throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = Calendar.current.timeZone
        dateFormatter.formatOptions = .withFullDate

        let requestBody: [String: String] = [
            "startDate": dateFormatter.string(from: startDate),
            "endDate": dateFormatter.string(from: endDate),
            "displayName": competitionName,
            "ianaTimezone": TimeZone.current.identifier
        ]

        let _: EmptyResponse = try await makeRequestWithUserAuthentication(url: "\(serverEnvironmentManager.baseUrl)/competitions",
                                                                           method: .post,
                                                                           body: requestBody)
    }

    public func joinCompetition(competitionId: UUID, competitionToken: String) async throws {
        let requestBody: [String: String] = [
            "accessToken": competitionToken,
            "competitionId": competitionId.uuidString
        ]

        let _: EmptyResponse = try await makeRequestWithUserAuthentication(url: "\(serverEnvironmentManager.baseUrl)/competitions/join",
                                                                           method: .post,
                                                                           body: requestBody)
    }

    public func removeUserFromCompetition(userId: String, competitionId: UUID) async throws {
        let requestBody: [String: String] = [
            "competitionId": competitionId.uuidString,
            "userId": userId.description
        ]

        let _: EmptyResponse = try await makeRequestWithUserAuthentication(url: "\(serverEnvironmentManager.baseUrl)/competitions/leave",
                                                                           method: .post,
                                                                           body: requestBody)
    }

    public func getCompetitionDescription(competitionId: UUID, competitionToken: String) async throws -> CompetitionDescription {
        let requestBody: [String: String] = [
            "competitionId": competitionId.uuidString,
            "competitionAccessToken": competitionToken
        ]

        return try await makeRequestWithUserAuthentication(url: "\(serverEnvironmentManager.baseUrl)/competitions/description",
                                                           method: .post,
                                                           body: requestBody)
    }

    /// The user must be the admin of the competition, otherwise the request will be rejected
    public func getCompetitionAdminDetails(competitionId: UUID) async throws -> CompetitionAdminDetails {
        return try await makeRequestWithUserAuthentication(url: "\(serverEnvironmentManager.baseUrl)/competitions/\(competitionId.uuidString)/adminDetail",
                                                           method: .get)
    }

    /// The user must be the admin of the competition, otherwise the request will be rejected
    public func deleteCompetition(competitionId: UUID) async throws {
        let requestBody: [String: String] = [
            "competitionId": competitionId.uuidString
        ]

        let _: EmptyResponse = try await makeRequestWithUserAuthentication(url: "\(serverEnvironmentManager.baseUrl)/competitions/delete",
                                                                           method: .post,
                                                                           body: requestBody)
    }
}
