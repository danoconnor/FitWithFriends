//
//  MockCompetitionManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockCompetitionManager: ICompetitionManager {
    var return_error: Error?

    @Published var return_competitionOverviews: [UUID: CompetitionOverview] = [:]
    public var competitionOverviews: [UUID : CompetitionOverview] {
        return return_competitionOverviews
    }

    var competitionOverviewsPublisher: Published<[UUID : CompetitionOverview]>.Publisher { $return_competitionOverviews }

    public init() {
        // Default to having a competition
        let results = [
            UserCompetitionPoints(userId: "user_1", firstName: "Test", lastName: "User 1", total: 300, today: 125),
            UserCompetitionPoints(userId: "user_2", firstName: "Test", lastName: "User 2", total: 425, today: 75),
            UserCompetitionPoints(userId: "user_3", firstName: "Test", lastName: "User 3", total: 100, today: 0)
        ]
        
        return_competitionOverviews = [
            UUID(): CompetitionOverview(start: Date(), end: Date().addingTimeInterval(TimeInterval.xtDays(7)), currentResults: results),
            UUID(): CompetitionOverview(start: Date(), end: Date().addingTimeInterval(TimeInterval.xtDays(7)), currentResults: results),
            UUID(): CompetitionOverview(start: Date(), end: Date().addingTimeInterval(TimeInterval.xtDays(7)), currentResults: results),
        ]
    }

    public var param_createCompetition_startDate: Date?
    public var param_createCompetition_endDate: Date?
    public var param_createCompetition_competitionName: String?
    public var return_createCompetition_error: Error?

    public var createCompetitionCallCount = 0
    public func createCompetition(startDate: Date, endDate: Date, competitionName: String) async throws {
        createCompetitionCallCount += 1
        param_createCompetition_startDate = startDate
        param_createCompetition_endDate = endDate
        param_createCompetition_competitionName = competitionName

        await MockUtilities.delayOneSecond()

        if let error = return_createCompetition_error {
            throw error
        }
    }

    public var refreshCompetitionOverviewsCallCount = 0
    public func refreshCompetitionOverviews() async {
        refreshCompetitionOverviewsCallCount += 1
    }

    public var param_joinCompetition_competitionId: UUID?
    public var param_joinCompetition_competitionToken: String?
    public var return_joinCompetition_error: Error?

    public var joinCompetitionCallCount = 0
    public func joinCompetition(competitionId: UUID, competitionToken: String) async throws {
        joinCompetitionCallCount += 1
        param_joinCompetition_competitionId = competitionId
        param_joinCompetition_competitionToken = competitionToken

        if let error = return_joinCompetition_error {
            throw error
        }
    }

    public var param_leaveCompetition_competitionId: UUID?
    public var return_leaveCompetition_error: Error?

    public var leaveCompetitionCallCount = 0
    public func leaveCompetition(competitionId: UUID) async throws {
        leaveCompetitionCallCount += 1
        param_leaveCompetition_competitionId = competitionId

        if let error = return_leaveCompetition_error {
            throw error
        }
    }

    public var param_removeUserFromCompetition_competitionId: UUID?
    public var param_removeUserFromCompetition_targetUser: String?
    public var return_removeUserFromCompetition_error: Error?

    public var removeUserFromCompetitionCallCount = 0
    public func removeUserFromCompetition(competitionId: UUID, targetUser: String) async throws {
        removeUserFromCompetitionCallCount += 1
        param_removeUserFromCompetition_competitionId = competitionId
        param_removeUserFromCompetition_targetUser = targetUser

        if let error = return_removeUserFromCompetition_error {
            throw error
        }
    }

    public var param_getCompetitionDescription_competitionId: UUID?
    public var param_getCompetitionDescription_competitionToken: String?
    public var return_getCompetitionDescription: CompetitionDescription?
    public var return_getCompetitionDescription_error: Error?

    public var getCompetitionDescriptionCallCount = 0
    public func getCompetitionDescription(for competitionId: UUID, competitionToken: String) async throws -> CompetitionDescription {
        getCompetitionDescriptionCallCount += 1
        param_getCompetitionDescription_competitionId = competitionId
        param_getCompetitionDescription_competitionToken = competitionToken

        if let error = return_getCompetitionDescription_error {
            throw error
        }

        guard let description = return_getCompetitionDescription else {
            throw NSError(domain: "Mock", code: 0, userInfo: nil)
        }

        return description
    }

    public var getCompetitionAdminDetailCallCount = 0
    public func getCompetitionAdminDetail(for competitionId: UUID) async throws -> CompetitionAdminDetails {
        getCompetitionAdminDetailCallCount += 1
        // Mock implementation
        throw NSError(domain: "Mock", code: 0, userInfo: nil)
    }

    public var deleteCompetitionCallCount = 0
    public func deleteCompetition(competitionId: UUID) async throws {
        deleteCompetitionCallCount += 1
        // Mock implementation
    }

    @Published var return_publicCompetitions: [PublicCompetition] = []
    var publicCompetitions: [PublicCompetition] {
        return return_publicCompetitions
    }

    var publicCompetitionsPublisher: Published<[PublicCompetition]>.Publisher { $return_publicCompetitions }

    public var refreshPublicCompetitionsCallCount = 0
    public func refreshPublicCompetitions() async {
        refreshPublicCompetitionsCallCount += 1
    }

    public var param_joinPublicCompetition_competitionId: UUID?
    public var return_joinPublicCompetition_error: Error?

    public var joinPublicCompetitionCallCount = 0
    public func joinPublicCompetition(competitionId: UUID) async throws {
        joinPublicCompetitionCallCount += 1
        param_joinPublicCompetition_competitionId = competitionId

        if let error = return_joinPublicCompetition_error {
            throw error
        }
    }

    public var param_getUserCompetitionDetails_competitionId: UUID?
    public var param_getUserCompetitionDetails_userId: String?
    public var return_getUserCompetitionDetails: UserCompetitionDailyDetails?
    public var return_getUserCompetitionDetails_error: Error?

    public var getUserCompetitionDetailsCallCount = 0
    public func getUserCompetitionDetails(competitionId: UUID, userId: String) async throws -> UserCompetitionDailyDetails {
        getUserCompetitionDetailsCallCount += 1
        param_getUserCompetitionDetails_competitionId = competitionId
        param_getUserCompetitionDetails_userId = userId

        if let error = return_getUserCompetitionDetails_error {
            throw error
        }

        guard let details = return_getUserCompetitionDetails else {
            throw NSError(domain: "Mock", code: 0, userInfo: nil)
        }

        return details
    }
}
