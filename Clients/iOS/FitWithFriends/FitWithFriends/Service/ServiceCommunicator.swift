//
//  ServiceCommunicator.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

class ServiceCommunicator {
    private let httpConnector: HttpConnector
    private let tokenManager: TokenManager

    init(httpConnector: HttpConnector,
         tokenManager: TokenManager) {
        self.httpConnector = httpConnector
        self.tokenManager = tokenManager
    }

    /// Creates a new user with the given credentials/user info. Will return an error if the username already exists
    func createUser(username: String, password: String, displayName: String, completion: @escaping (Result<User, Error>) -> Void) {
        
    }

    /// Gets a token using the user's credentials
    func getToken(username: String, password: String, completion: @escaping (Result<Token, Error>) -> Void) {

    }

    /// Gets a token using the refresh token contained in the previously acquired access token
    func getToken(token: Token, completion: @escaping (Result<Token, Error>) -> Void) {

    }

    /// Makes a request to the service and authenticates by providing the client ID/secret.
    /// This request is not authenticated as a specific user
    private func makeRequestWithClientAuthentication<T: Decodable>(url: String, method: HttpMethod, completion: @escaping (Result<T, Error>) -> Void) {

    }

    /// Makes a request using a user token.
    /// If there is no available token, an error will be returned and the caller should use AuthenticationManager to fetch a new token
    /// If there is a token available, but it is expired, then an attempt will be made to automatically fetch a new access token using a stored refresh token
    private func makeRequestWithUserAuthentication<T: Decodable>(url: String, method: HttpMethod, completion: @escaping (Result<T, Error>) -> Void) {

    }
}
