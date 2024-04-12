//
//  ICompetitionService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/25/24.
//

import Foundation

public protocol ICompetitionService {
    
    /// Gets the list of competition ids that the user is a member of
    /// - Parameter userId: The userId
    /// - Returns: A list of the competition ids that the user is a member of, or an error
    func getUsersCompetitions(userId: String) async throws -> [UUID]

    /// Get the competition overview, which contains a list of the users in the competition and their current scores
    /// The logged in user must be a member of the target competition
    /// - Parameter competitionId: The competition id
    /// - Returns: The competition overview, or a relevant error
    func getCompetitionOverview(competitionId: UUID) async throws -> CompetitionOverview

    /// Create a new competition. The logged in user will become the admin of the new competition
    /// - Parameters:
    ///   - startDate: The start date
    ///   - endDate: The end date
    ///   - competitionName: The competition name
    func createCompetition(startDate: Date, endDate: Date, competitionName: String) async throws

    /// Join the given competition
    /// - Parameters:
    ///   - competitionId: The competition id
    ///   - competitionToken: The competition access token
    func joinCompetition(competitionId: UUID, competitionToken: String) async throws

    /// Remove the user from the competition. The user can be the logged in user, or a different user in the competition
    /// Only admins may successfully remove someone other than themselves from the competition
    /// - Parameters:
    ///   - userId: The target user id
    ///   - competitionId: The competition id
    func removeUserFromCompetition(userId: String, competitionId: UUID) async throws

    /// Get the competition description. Intended to show the user some info about the competition before joining,
    /// so the user does not need to be a member of the competition yet. But they do need to have the competition access token (shared by the admin)
    /// - Parameters:
    ///   - competitionId: The competition id
    ///   - competitionToken: The competition access token
    /// - Returns: The competition description, or an error
    func getCompetitionDescription(competitionId: UUID, competitionToken: String) async throws -> CompetitionDescription

    /// Get the competition admin details, most importantly the competition access token
    /// The user must be the admin of the competition, otherwise this will fail
    /// - Parameter competitionId: The competitionId
    /// - Returns: The competition admin details, or an error
    func getCompetitionAdminDetails(competitionId: UUID) async throws -> CompetitionAdminDetails

    /// Delete the given competition. The user must be the admin of the competition, otherwise this will result in an error
    /// - Parameter competitionId: The competitionId to delete
    func deleteCompetition(competitionId: UUID) async throws
}
