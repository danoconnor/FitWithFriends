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
    public func getUsersCompetitions(userId: String) async throws -> [UUID] {
        param_getUsersCompetitions_userId = userId

        if let retVal = return_getUsersCompetitions {
            return retVal
        } else {
            throw HttpError.generic
        }
    }
    
    public var param_getCompetitionOverview_competitionId: UUID?
    public var return_getCompetitionOverview: CompetitionOverview?
    public func getCompetitionOverview(competitionId: UUID) async throws -> CompetitionOverview {
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
    public func createCompetition(startDate: Date, endDate: Date, competitionName: String) async throws {
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
    public func joinCompetition(competitionId: UUID, competitionToken: String) async throws {
        param_joinCompetition_competitionId = competitionId
        param_joinCompetition_competitionToken = competitionToken

        if let error = return_joinCompetition_error {
            throw error
        }
    }
    
    public var param_removeUserFromCompetition_userId: String?
    public var param_removeUserFromCompetition_competitionId: UUID?
    public var return_removeUserFromCompetition_error: Error?
    public func removeUserFromCompetition(userId: String, competitionId: UUID) async throws {
        param_removeUserFromCompetition_userId = userId
        param_removeUserFromCompetition_competitionId = competitionId
        
        if let error = return_removeUserFromCompetition_error {
            throw error
        }
    }
    
    public var param_getCompetitionDescription_competitionId: UUID?
    public var param_getCompetitionDescription_competitionToken: String?
    public var return_getCompetitionDescription: CompetitionDescription?
    public func getCompetitionDescription(competitionId: UUID, competitionToken: String) async throws -> CompetitionDescription {
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
    public func getCompetitionAdminDetails(competitionId: UUID) async throws -> CompetitionAdminDetails {
        param_getCompetitionAdminDetails_competitionId = competitionId
        
        if let retVal = return_getCompetitionAdminDetails {
            return retVal
        } else {
            throw HttpError.generic
        }
    }
    
    public var param_deleteCompetition_competitionId: UUID?
    public var return_deleteCompetition: Error?
    public func deleteCompetition(competitionId: UUID) async throws {
        param_deleteCompetition_competitionId = competitionId
        
        if let error = return_deleteCompetition {
            throw error
        }
    }
}
