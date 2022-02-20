//
//  HttpConnector.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

class HttpConnector {
    func makeRequest<T: Decodable>(url: String, headers: [String: String]? = nil, body: [String: String]? = nil, method: HttpMethod) async -> Result<T, Error> {
        guard let urlObj = URL(string: url) else {
            return .failure(HttpError.invalidUrl(url: url))
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

        do {
            let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)

            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.traceError(message: "Response was not HTTPURLResponse")
                return .failure(HttpError.generic)
            }

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                var error = HttpError.generic
                if (400 ... 499).contains(httpResponse.statusCode) {
                    error = HttpError.clientError(code: httpResponse.statusCode)
                } else if (500 ... 599).contains(httpResponse.statusCode) {
                    error = HttpError.serverError(code: httpResponse.statusCode)
                }

                var message: String?
                if let responseString = String(data: data, encoding: .utf8) {
                    message = responseString
                }

                Logger.traceError(message: "Received HTTP error. \(message ?? "")", error: error)
                return .failure(error)
            }

            // If the caller doesn't expect any data back, then return here so we don't fail during parsing
            if T.self == EmptyResponse.self {
                return .success(EmptyResponse() as! T)
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .formatted(DateFormatter.isoFormatter)

                let parsedData = try decoder.decode(T.self, from: data)
                return .success(parsedData)
            } catch {
                Logger.traceError(message: "Failed to parse response of type \(T.self) from data \(String(data: data, encoding: .utf8) ?? "nil")", error: error)
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }
}
