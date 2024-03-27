//
//  MockCompetitionService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockCompetitionService: ICompetitionService {
    public var param_getUsersCompetitions_userId: String?
    public var return_getUsersCompetitions: Result<[UUID], any Error>?
    public func getUsersCompetitions(userId: String) async -> Result<[UUID], any Error> {
        param_getUsersCompetitions_userId = userId
        
        return return_getUsersCompetitions ?? .failure(HttpError.generic)
    }
    
    public var param_getCompetitionOverview_competitionId: UUID?
    public var return_getCompetitionOverview: Result<CompetitionOverview, Error>?
    public func getCompetitionOverview(competitionId: UUID) async -> Result<CompetitionOverview, Error> {
        param_getCompetitionOverview_competitionId = competitionId
        
        return return_getCompetitionOverview ?? .failure(HttpError.generic)
    }
    
    public var param_createCompetition_startDate: Date?
    public var param_createCompetition_endDate: Date?
    public var param_createCompetition_competitionName: String?
    public var return_createCompetition_error: Error?
    public func createCompetition(startDate: Date, endDate: Date, competitionName: String) async -> Error? {
        param_createCompetition_startDate = startDate
        param_createCompetition_endDate = endDate
        param_createCompetition_competitionName = competitionName
        
        return return_createCompetition_error
    }
    
    public var param_joinCompetition_competitionId: UUID?
    public var param_joinCompetition_competitionToken: String?
    public var return_joinCompetition_error: Error?
    public func joinCompetition(competitionId: UUID, competitionToken: String) async -> Error? {
        param_joinCompetition_competitionId = competitionId
        param_joinCompetition_competitionToken = competitionToken
        
        return return_joinCompetition_error
    }
    
    public var param_removeUserFromCompetition_userId: String?
    public var param_removeUserFromCompetition_competitionId: UUID?
    public var return_removeUserFromCompetition_error: Error?
    public func removeUserFromCompetition(userId: String, competitionId: UUID) async -> Error? {
        param_removeUserFromCompetition_userId = userId
        param_removeUserFromCompetition_competitionId = competitionId
        
        return return_removeUserFromCompetition_error
    }
    
    public var param_getCompetitionDescription_competitionId: UUID?
    public var param_getCompetitionDescription_competitionToken: String?
    public var return_getCompetitionDescription: Result<CompetitionDescription, Error>?
    public func getCompetitionDescription(competitionId: UUID, competitionToken: String) async -> Result<CompetitionDescription, Error> {
        param_getCompetitionDescription_competitionId = competitionId
        param_getCompetitionDescription_competitionToken = competitionToken
        
        return return_getCompetitionDescription ?? .failure(HttpError.generic)
    }
    
    public var param_getCompetitionAdminDetails_competitionId: UUID?
    public var return_getCompetitionAdminDetails: Result<CompetitionAdminDetails, Error>?
    public func getCompetitionAdminDetails(competitionId: UUID) async -> Result<CompetitionAdminDetails, Error> {
        param_getCompetitionAdminDetails_competitionId = competitionId
        
        return return_getCompetitionAdminDetails ?? .failure(HttpError.generic)
    }
    
    public var param_deleteCompetition_competitionId: UUID?
    public var return_deleteCompetition: Error?
    public func deleteCompetition(competitionId: UUID) async -> Error? {
        param_deleteCompetition_competitionId = competitionId
        
        return return_deleteCompetition
    }
}
