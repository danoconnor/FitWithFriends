//
//  MockAuthenticationService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockAuthenticationService: IAuthenticationService {
    public var param_getToken_token: Token?
    public var return_getToken: Token?
    public func getToken(token: Token) async throws -> Token {
        param_getToken_token = token
        
        // Simulate a network delay
        await MockUtilities.delayOneSecond()

        if let retVal = return_getToken {
            return retVal
        } else {
            throw HttpError.generic
        }
    }
    
    public var param_getTokenFromAppleId_userId: String?
    public var param_getTokenFromAppleId_idToken: String?
    public var param_getTokenFromAppleId_authorizationCode: String?
    public var return_getTokenFromAppleId: Token?
    public func getTokenFromAppleId(userId: String, idToken: String, authorizationCode: String) async throws -> Token {
        param_getTokenFromAppleId_userId = userId
        param_getTokenFromAppleId_idToken = idToken
        param_getTokenFromAppleId_authorizationCode = authorizationCode

        // Simulate a network delay
        await MockUtilities.delayOneSecond()

        if let retVal = return_getTokenFromAppleId {
            return retVal
        } else {
            throw HttpError.generic
        }
    }
}
