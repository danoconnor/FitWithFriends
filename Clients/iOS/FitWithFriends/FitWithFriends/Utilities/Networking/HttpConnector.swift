//
//  HttpConnector.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

class HttpConnector {
    func makeRequest<T: Decodable>(url: String, headers: [String: Any]? = nil, method: HttpMethod, completion: @escaping (Result<T, Error>) -> Void) {
        guard let urlObj = URL(string: url) else {
            completion(.failure(HttpError.invalidUrl(url: url)))
            return
        }

        var request = URLRequest(url: urlObj)
        request.httpMethod = method.rawValue

        let configuration = URLSessionConfiguration.default

        if let headers = headers {
            configuration.httpAdditionalHeaders = headers
        }

        let session = URLSession.init(configuration: configuration)

        session.dataTask(with: request) { data, urlResponse, error in
            // TODO: Parse response for error details
            if let error = error {
                completion(.failure(error))
                return
            }

            // If the caller doesn't expect any data back, then return here so we don't fail during parsing
            if T.self == EmptyReponse.self {
                completion(.success(EmptyReponse() as! T))
            }

            if let data = data {
                do {
                    let parsedData = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(parsedData))
                } catch {
                    Logger.traceError(message: "Failed to parse response", error: error)
                    completion(.failure(error))
                }
            }
        }
    }
}
