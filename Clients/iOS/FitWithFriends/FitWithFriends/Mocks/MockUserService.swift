//
//  MockUserService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockUserService: IUserService {
    public var param_createUser_firstName: String?
    public var param_createUser_lastName: String?
    public var param_createUser_userId: String?
    public var param_createUser_idToken: String?
    public var param_createUser_authorizationCode: String?
    public var return_creatUser_error: Error?
    public var createUserCallCount = 0
    
    public var return_deleteAccount_error: Error?
    public var deleteAccountCallCount = 0
    public func deleteAccount() async throws {
        deleteAccountCallCount += 1
        if let error = return_deleteAccount_error {
            throw error
        }
    }

    public func createUser(firstName: String,
                    lastName: String,
                    userId: String,
                    idToken: String,
                    authorizationCode: String) async throws {
        createUserCallCount += 1
        param_createUser_firstName = firstName
        param_createUser_lastName = lastName
        param_createUser_userId = userId
        param_createUser_idToken = idToken
        param_createUser_authorizationCode = authorizationCode
        
        // Simulate a network delay
        await MockUtilities.delayOneSecond()

        if let error = return_creatUser_error {
            throw error
        }
    }
}
