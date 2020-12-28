//
//  ServiceBase.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class ServiceBase {
    private let httpConnector: HttpConnector
    private let tokenManager: TokenManager

    init(httpConnector: HttpConnector,
         tokenManager: TokenManager) {
        self.httpConnector = httpConnector
        self.tokenManager = tokenManager
    }

    /// Gets a new access token using the refresh token
    func getToken(token: Token, completion: @escaping (Result<Token, Error>) -> Void) {
        Logger.traceInfo(message: "Requesting new access token using refresh token")

        let requestBody: [String: String] = [
            RequestConstants.Body.grantType: RequestConstants.Body.refreshTokenGrant,
            RequestConstants.Body.refreshToken: token.refreshToken
        ]

        makeRequestWithClientAuthentication(url: "\(SecretConstants.serviceBaseUrl)/oauth/token",
                                            method: .post,
                                            body: requestBody,
                                            completion: { (result: Result<Token, Error>) in
                                                switch result {
                                                case let .success(token):
                                                    completion(.success(token))
                                                case let .failure(error):
                                                    completion(.failure(error))
                                                }
                                            })
    }

    /// Makes a request to the service and authenticates by providing the client ID/secret.
    /// This request is not authenticated as a specific user
    func makeRequestWithClientAuthentication<T: Decodable>(url: String, method: HttpMethod, body: [String: String]? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        let authString = "\(SecretConstants.clientId):\(SecretConstants.clientSecret)"
        let base64AuthString = authString.data(using: .utf8)!.base64EncodedString()

        let headers: [String: String] = [
            RequestConstants.Headers.authorization: "Basic \(base64AuthString)"
        ]

        httpConnector.makeRequest(url: url, headers: headers, body: body, method: method, completion: completion)
    }

    /// Makes a request using a user token.
    /// If there is no available token, an error will be returned and the caller should prompt the user for credentials and use those to fetch a new token
    /// If there is a token available, but it is expired, then an attempt will be made to automatically fetch a new access token using a stored refresh token
    func makeRequestWithUserAuthentication<T: Decodable>(url: String, method: HttpMethod, body: [String: String]? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        let tokenResult = tokenManager.getCachedToken()

        var headers: [String: Any] = [:]

        switch tokenResult {
        case let .success(token):
            headers[RequestConstants.Headers.authorization] = "Bearer \(token.accessToken)"
        case let .failure(error):
            switch error {
            case let .expired(token):
                Logger.traceInfo(message: "Found token for request but access token is expired")
                refreshTokenAndRetryRequest(expiredToken: token, url: url, method: method, body: body, completion: completion)
            default:
                completion(.failure(error))
                return
            }
        }
    }

    private func refreshTokenAndRetryRequest<T: Decodable>(expiredToken: Token, url: String, method: HttpMethod, body: [String: String]? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        getToken(token: expiredToken) { [weak self] result in
            switch result {
            case let .success(token):
                self?.tokenManager.storeToken(token)
                self?.makeRequestWithUserAuthentication(url: url, method: method, body: body, completion: completion)
            case let .failure(error):
                Logger.traceError(message: "Could not refresh token", error: error)
                completion(.failure(error))
            }
        }
    }
}
