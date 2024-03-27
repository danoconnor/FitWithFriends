//
//  MockAuthenticationService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockAuthenticationService: IAuthenticationService {
    public var param_getToken_token: Token?
    public var return_getToken: Result<Token, Error>?
    public func getToken(token: Token) async -> Result<Token, Error> {
        param_getToken_token = token
        
        // Simulate a network delay
        await MockUtilities.delayOneSecond()
        
        return return_getToken ?? .failure(HttpError.generic)
    }
    
    public var param_getTokenFromAppleId_userId: String?
    public var param_getTokenFromAppleId_idToken: String?
    public var param_getTokenFromAppleId_authorizationCode: String?
    public var return_getTokenFromAppleId: Result<Token, Error>?
    public func getTokenFromAppleId(userId: String, idToken: String, authorizationCode: String) async -> Result<Token, Error> {
        param_getTokenFromAppleId_userId = userId
        param_getTokenFromAppleId_idToken = idToken
        param_getTokenFromAppleId_authorizationCode = authorizationCode

        // Simulate a network delay
        await MockUtilities.delayOneSecond()
        
        return return_getTokenFromAppleId ?? .failure(HttpError.generic)
    }
}
