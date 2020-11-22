//
//  HttpConnector.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

class HttpConnector {
    func makeRequest<T: Decodable>(url: String, headers: [String: Any]? = nil, body: [String: String]? = nil, method: HttpMethod, completion: @escaping (Result<T, Error>) -> Void) {
        guard let urlObj = URL(string: url) else {
            completion(.failure(HttpError.invalidUrl(url: url)))
            return
        }

        var request = URLRequest(url: urlObj)
        request.httpMethod = method.rawValue

        if let body = body {
            var kvPairs: [String] = []
            body.forEach {
                kvPairs.append("\($0.key)=\($0.value)")
            }

            let bodyString = kvPairs.joined(separator: "&")
            request.httpBody = bodyString.data(using: .utf8)
        }

        let configuration = URLSessionConfiguration.default
        if let headers = headers {
            configuration.httpAdditionalHeaders = headers
        }

        let session = URLSession.init(configuration: configuration)

        let dataTask = session.dataTask(with: request) { data, urlResponse, error in
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

        dataTask.resume()
    }
}
