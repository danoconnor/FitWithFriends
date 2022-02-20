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

    private static let refreshTokenQueue = DispatchQueue(label: "RefreshTokenQueue")

    init(httpConnector: HttpConnector,
         tokenManager: TokenManager) {
        self.httpConnector = httpConnector
        self.tokenManager = tokenManager
    }

    /// Gets a new access token using the refresh token
    func getToken(token: Token) async -> Result<Token, Error> {
        dispatchPrecondition(condition: .onQueue(ServiceBase.refreshTokenQueue))

        // Sometimes there are multiple concurrent calls to refresh the token,
        // which can invalidate previously issued tokens
        // We use the DispatchQueue to prevent concurrent calls, so check here if we
        // have already gotten a new, valid token
        if let currentToken = self.tokenManager.getCachedToken().xtSuccess,
           !currentToken.isAccessTokenExpired {
            Logger.traceInfo(message: "Tried to refresh token, but already have a valid token in the cache")
            return .success(currentToken)
        }

        Logger.traceInfo(message: "Requesting new access token using refresh token")

        let requestBody: [String: String] = [
            RequestConstants.Body.grantType: RequestConstants.Body.refreshTokenGrant,
            RequestConstants.Body.refreshToken: token.refreshToken
        ]

        return await self.makeRequestWithClientAuthentication(url: "\(SecretConstants.serviceBaseUrl)/oauth/token",
                                                              method: .post,
                                                              body: requestBody)
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
