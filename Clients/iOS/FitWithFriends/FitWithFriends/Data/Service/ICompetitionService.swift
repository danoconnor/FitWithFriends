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
    func getUsersCompetitions(userId: String) async -> Result<[UUID], Error>

    /// Get the competition overview, which contains a list of the users in the competition and their current scores
    /// The logged in user must be a member of the target competition
    /// - Parameter competitionId: The competition id
    /// - Returns: The competition overview, or a relevant error
    func getCompetitionOverview(competitionId: UUID) async -> Result<CompetitionOverview, Error>
    
    /// Create a new competition. The logged in user will become the admin of the new competition
    /// - Parameters:
    ///   - startDate: The start date
    ///   - endDate: The end date
    ///   - competitionName: The competition name
    /// - Returns: Nil if the request succeeds, or a relevant error if it failed
    func createCompetition(startDate: Date, endDate: Date, competitionName: String) async -> Error?

    /// Join the given competition
    /// - Parameters:
    ///   - competitionId: The competition id
    ///   - competitionToken: The competition access token
    /// - Returns: Nil if the request succeeds, or a relevant error if it failed
    func joinCompetition(competitionId: UUID, competitionToken: String) async -> Error?

    /// Remove the user from the competition. The user can be the logged in user, or a different user in the competition
    /// Only admins may successfully remove someone other than themselves from the competition
    /// - Parameters:
    ///   - userId: The target user id
    ///   - competitionId: The competition id
    /// - Returns: Nil if the request succeeds, or a relevant error if it failed
    func removeUserFromCompetition(userId: String, competitionId: UUID) async -> Error?

    /// Get the competition description. Intended to show the user some info about the competition before joining,
    /// so the user does not need to be a member of the competition yet. But they do need to have the competition access token (shared by the admin)
    /// - Parameters:
    ///   - competitionId: The competition id
    ///   - competitionToken: The competition access token
    /// - Returns: The competition description, or an error
    func getCompetitionDescription(competitionId: UUID, competitionToken: String) async -> Result<CompetitionDescription, Error>

    /// Get the competition admin details, most importantly the competition access token
    /// The user must be the admin of the competition, otherwise this will fail
    /// - Parameter competitionId: The competitionId
    /// - Returns: The competition admin details, or an error
    func getCompetitionAdminDetails(competitionId: UUID) async -> Result<CompetitionAdminDetails, Error>

    /// Delete the given competition. The user must be the admin of the competition, otherwise this will result in an error
    /// - Parameter competitionId: The competitionId to delete
    /// - Returns: Nil if the request succeeds, or the relevant error if it fails
    func deleteCompetition(competitionId: UUID) async -> Error?
}
