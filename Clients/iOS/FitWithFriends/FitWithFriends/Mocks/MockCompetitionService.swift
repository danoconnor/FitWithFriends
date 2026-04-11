//
//  MockCompetitionService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockCompetitionService: ICompetitionService {
    public var param_getUsersCompetitions_userId: String?
    public var return_getUsersCompetitions: [UUID]?
    public var getUsersCompetitionsCallCount = 0
    public func getUsersCompetitions(userId: String) async throws -> [UUID] {
        getUsersCompetitionsCallCount += 1
        param_getUsersCompetitions_userId = userId

        if let retVal = return_getUsersCompetitions {
            return retVal
        } else {
            throw HttpError.generic
        }
    }
    
    public var param_getCompetitionOverview_competitionId: UUID?
    public var return_getCompetitionOverview: CompetitionOverview?
    public var getCompetitionOverviewCallCount = 0
    public func getCompetitionOverview(competitionId: UUID) async throws -> CompetitionOverview {
        getCompetitionOverviewCallCount += 1
        param_getCompetitionOverview_competitionId = competitionId

        if let retVal = return_getCompetitionOverview {
            return retVal
        } else {
            throw HttpError.generic
        }
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

        if let error = return_createCompetition_error {
            throw error
        }
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
    
    public var param_removeUserFromCompetition_userId: String?
    public var param_removeUserFromCompetition_competitionId: UUID?
    public var return_removeUserFromCompetition_error: Error?
    public var removeUserFromCompetitionCallCount = 0
    public func removeUserFromCompetition(userId: String, competitionId: UUID) async throws {
        removeUserFromCompetitionCallCount += 1
        param_removeUserFromCompetition_userId = userId
        param_removeUserFromCompetition_competitionId = competitionId

        if let error = return_removeUserFromCompetition_error {
            throw error
        }
    }
    
    public var param_getCompetitionDescription_competitionId: UUID?
    public var param_getCompetitionDescription_competitionToken: String?
    public var return_getCompetitionDescription: CompetitionDescription?
    public var getCompetitionDescriptionCallCount = 0
    public func getCompetitionDescription(competitionId: UUID, competitionToken: String) async throws -> CompetitionDescription {
        getCompetitionDescriptionCallCount += 1
        param_getCompetitionDescription_competitionId = competitionId
        param_getCompetitionDescription_competitionToken = competitionToken

        if let retVal = return_getCompetitionDescription {
            return retVal
        } else {
            throw HttpError.generic
        }
    }
    
    public var param_getCompetitionAdminDetails_competitionId: UUID?
    public var return_getCompetitionAdminDetails: CompetitionAdminDetails?
    public var getCompetitionAdminDetailsCallCount = 0
    public func getCompetitionAdminDetails(competitionId: UUID) async throws -> CompetitionAdminDetails {
        getCompetitionAdminDetailsCallCount += 1
        param_getCompetitionAdminDetails_competitionId = competitionId
        
        if let retVal = return_getCompetitionAdminDetails {
            return retVal
        } else {
            throw HttpError.generic
        }
    }
    
    public var param_deleteCompetition_competitionId: UUID?
    public var return_deleteCompetition: Error?
    public var deleteCompetitionCallCount = 0
    public func deleteCompetition(competitionId: UUID) async throws {
        deleteCompetitionCallCount += 1
        param_deleteCompetition_competitionId = competitionId

        if let error = return_deleteCompetition {
            throw error
        }
    }

    public var return_getPublicCompetitions: PublicCompetitionsResponse?
    public var getPublicCompetitionsCallCount = 0
    public func getPublicCompetitions() async throws -> PublicCompetitionsResponse {
        getPublicCompetitionsCallCount += 1

        if let retVal = return_getPublicCompetitions {
            return retVal
        } else {
            throw HttpError.generic
        }
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
    public var getUserCompetitionDetailsCallCount = 0
    public func getUserCompetitionDetails(competitionId: UUID, userId: String) async throws -> UserCompetitionDailyDetails {
        getUserCompetitionDetailsCallCount += 1
        param_getUserCompetitionDetails_competitionId = competitionId
        param_getUserCompetitionDetails_userId = userId

        if let retVal = return_getUserCompetitionDetails {
            return retVal
        } else {
            throw HttpError.generic
        }
    }
}
