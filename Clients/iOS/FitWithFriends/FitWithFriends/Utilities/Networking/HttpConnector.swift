//
//  HttpConnector.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

class HttpConnector {
    func makeRequest<T: Decodable>(url: String, headers: [String: String]? = nil, body: [String: String]? = nil, method: HttpMethod, completion: @escaping (Result<T, Error>) -> Void) {
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

        if let headers = headers {
            headers.forEach {
                request.setValue($0.value, forHTTPHeaderField: $0.key)
            }
        }

        let dataTask = URLSession.shared.dataTask(with: request) { data, urlResponse, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                Logger.traceError(message: "Response was not HTTPURLResponse")
                completion(.failure(HttpError.generic))
                return
            }

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                var error = HttpError.generic
                if (400 ... 499).contains(httpResponse.statusCode) {
                    error = HttpError.clientError(code: httpResponse.statusCode)
                } else if (500 ... 599).contains(httpResponse.statusCode) {
                    error = HttpError.serverError(code: httpResponse.statusCode)
                }

                var message: String?
                if let responseData = data,
                   let responseString = String(data: responseData, encoding: .utf8) {
                    message = responseString
                }

                Logger.traceError(message: "Received HTTP error. \(message ?? "")", error: error)
                completion(.failure(error))
                return
            }

            // If the caller doesn't expect any data back, then return here so we don't fail during parsing
            if T.self == EmptyReponse.self {
                completion(.success(EmptyReponse() as! T))
                return
            }

            if let data = data {
                do {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .formatted(dateFormatter)

                    let parsedData = try decoder.decode(T.self, from: data)
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
