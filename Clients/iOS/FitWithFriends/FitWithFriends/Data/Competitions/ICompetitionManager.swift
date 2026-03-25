import Foundation

/**
 A protocol defining the interface for managing competitions.
 */
protocol ICompetitionManager: AnyObject {
    /// A dictionary of competition overviews, keyed by their unique identifiers.
    var competitionOverviews: [UUID: CompetitionOverview] { get }

    /// A publisher for changes to the competitionOverviews
    var competitionOverviewsPublisher: Published<[UUID: CompetitionOverview]>.Publisher { get }

    /// Creates a new competition with the specified start date, end date, and name.
    /// - Parameters:
    ///   - startDate: The start date of the competition.
    ///   - endDate: The end date of the competition.
    ///   - competitionName: The name of the competition.
    /// - Throws: An error if the competition could not be created.
    func createCompetition(startDate: Date, endDate: Date, competitionName: String) async throws

    /// Refreshes the competition overviews by fetching the latest data.
    func refreshCompetitionOverviews() async

    /// Joins a competition using the provided competition ID and token.
    /// - Parameters:
    ///   - competitionId: The unique identifier of the competition to join.
    ///   - competitionToken: The token required to join the competition.
    /// - Throws: An error if the operation fails.
    func joinCompetition(competitionId: UUID, competitionToken: String) async throws

    /// Leaves a competition with the specified ID.
    /// - Parameter competitionId: The unique identifier of the competition to leave.
    /// - Throws: An error if the operation fails.
    func leaveCompetition(competitionId: UUID) async throws

    /// Removes a user from a competition.
    /// - Parameters:
    ///   - competitionId: The unique identifier of the competition.
    ///   - targetUser: The ID of the user to remove.
    /// - Throws: An error if the operation fails.
    func removeUserFromCompetition(competitionId: UUID, targetUser: String) async throws

    /// Retrieves the description of a competition.
    /// - Parameters:
    ///   - competitionId: The unique identifier of the competition.
    ///   - competitionToken: The token required to access the competition.
    /// - Returns: A `CompetitionDescription` object containing details about the competition.
    /// - Throws: An error if the operation fails.
    func getCompetitionDescription(for competitionId: UUID, competitionToken: String) async throws -> CompetitionDescription

    /// Retrieves administrative details for a competition.
    /// - Parameter competitionId: The unique identifier of the competition.
    /// - Returns: A `CompetitionAdminDetails` object containing administrative details about the competition.
    /// - Throws: An error if the operation fails.
    func getCompetitionAdminDetail(for competitionId: UUID) async throws -> CompetitionAdminDetails

    /// Deletes a competition with the specified ID.
    /// - Parameter competitionId: The unique identifier of the competition to delete.
    /// - Throws: An error if the operation fails.
    func deleteCompetition(competitionId: UUID) async throws
}
