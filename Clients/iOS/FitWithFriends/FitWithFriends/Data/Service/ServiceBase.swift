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

    private static var activeRefreshTokenTask: Task<Result<Token, Error>, Error>?

    init(httpConnector: HttpConnector,
         tokenManager: TokenManager) {
        self.httpConnector = httpConnector
        self.tokenManager = tokenManager
    }

    /// Gets a new access token using the refresh token
    func getToken(token: Token) async -> Result<Token, Error> {
        guard let refreshToken = token.refreshToken else {
            return .failure(TokenError.notFound)
        }

        // Sometimes there are multiple concurrent calls to refresh the token,
        // which can invalidate previously issued tokens.
        // Make sure there is only one refresh token task at a time
        if let existingTask = ServiceBase.activeRefreshTokenTask {
            do {
                Logger.traceInfo(message: "There is an existing refresh token task, waiting for results")
                return try await existingTask.value
            } catch {
                Logger.traceError(message: "Failed to wait for existing refresh token task", error: error)
                return .failure(error)
            }
        }

        let task = Task<Result<Token, Error>, Error> {
            Logger.traceInfo(message: "Requesting new access token using refresh token")

            let requestBody: [String: String] = [
                RequestConstants.Body.grantType: RequestConstants.Body.refreshTokenGrant,
                RequestConstants.Body.refreshToken: refreshToken
            ]

            let result: Result<Token, Error> = await self.makeRequestWithClientAuthentication(url: "\(SecretConstants.serviceBaseUrl)/oauth/token",
                                                                                              method: .post,
                                                                                              body: requestBody)

            ServiceBase.activeRefreshTokenTask = nil
            return result
        }

        ServiceBase.activeRefreshTokenTask = task

        do {
            return try await task.value
        } catch {
            Logger.traceError(message: "Failed to wait for refresh token task", error: error)
            return .failure(error)
        }
    }

    /// Makes a request to the service and authenticates by providing the client ID/secret.
    /// This request is not authenticated as a specific user
    func makeRequestWithClientAuthentication<T: Decodable>(url: String, method: HttpMethod, body: [String: String]? = nil) async -> Result<T, Error> {
        let authString = "\(SecretConstants.clientId):\(SecretConstants.clientSecret)"
        let base64AuthString = authString.data(using: .utf8)!.base64EncodedString()

        let headers: [String: String] = [
            RequestConstants.Headers.authorization: "Basic \(base64AuthString)"
        ]

        return await httpConnector.makeRequest(url: url, headers: headers, body: body, method: method)
    }

    /// Makes a request using a user token.
    /// If there is no available token, an error will be returned and the caller should prompt the user for credentials and use those to fetch a new token
    /// If there is a token available, but it is expired, then an attempt will be made to automatically fetch a new access token using a stored refresh token
    func makeRequestWithUserAuthentication<T: Decodable>(url: String, method: HttpMethod, body: [String: String]? = nil) async -> Result<T, Error> {
        let tokenResult = tokenManager.getCachedToken()

        var headers: [String: String] = [:]

        switch tokenResult {
        case let .success(token):
            headers[RequestConstants.Headers.authorization] = "Bearer \(token.accessToken)"
            return await httpConnector.makeRequest(url: url, headers: headers, body: body, method: method)
        case let .failure(error):
            switch error {
            case let .expired(token):
                Logger.traceInfo(message: "Found token for request but access token is expired")
                return await refreshTokenAndRetryRequest(expiredToken: token, url: url, method: method, body: body)
            default:
                return .failure(error)
            }
        }
    }

    private func refreshTokenAndRetryRequest<T: Decodable>(expiredToken: Token,
                                                           url: String,
                                                           method: HttpMethod,
                                                           body: [String: String]? = nil) async -> Result<T, Error> {
        let tokenResult = await getToken(token: expiredToken)

        switch tokenResult {
        case let .success(token):
            tokenManager.storeToken(token)
            return await makeRequestWithUserAuthentication(url: url, method: method, body: body)
        case let .failure(error):
            Logger.traceError(message: "Could not refresh token", error: error)
            return .failure(error)
        }
    }
}
