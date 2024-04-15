//
//  HttpConnector.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

public class HttpConnector: IHttpConnector {
    public func makeRequest<T: Decodable>(url: String, headers: [String: String]? = nil, body: Encodable? = nil, method: HttpMethod) async throws -> T {
        guard let urlObj = URL(string: url) else {
            throw HttpError.invalidUrl(url: url)
        }

        var request = URLRequest(url: urlObj)
        request.httpMethod = method.rawValue

        if let body = body {
            // Our OAuth server requires the request to be in form-urlencoded format
            // so if the body is a [String: String], then send it as form-urlencoded
            // Otherwise, send it as standard json
            if let bodyDict = body as? [String: String] {
                var kvPairs: [String] = []
                bodyDict.forEach {
                    kvPairs.append("\($0.key)=\($0.value)")
                }

                let bodyString = kvPairs.joined(separator: "&")
                request.httpBody = bodyString.data(using: .utf8)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            } else {
                request.httpBody = try JSONEncoder.fwfDefaultEncoder.encode(body)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }

        if let headers = headers {
            headers.forEach {
                request.setValue($0.value, forHTTPHeaderField: $0.key)
            }
        }

        Logger.traceInfo(message: "Making \(method.rawValue) request with URL \(urlObj.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)

        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.traceError(message: "Response was not HTTPURLResponse")
            throw HttpError.generic
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(DateFormatter.isoFormatter)

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            var error = HttpError.generic

            let details = try? decoder.decode(FWFErrorDetails.self, from: data)

            if (400 ... 499).contains(httpResponse.statusCode) {
                error = HttpError.clientError(code: httpResponse.statusCode, details: details)
            } else if (500 ... 599).contains(httpResponse.statusCode) {
                error = HttpError.serverError(code: httpResponse.statusCode, details: details)
            }

            var message: String?
            if let responseString = String(data: data, encoding: .utf8) {
                message = responseString
            }

            Logger.traceError(message: "Received HTTP error. \(message ?? "")", error: error)
            throw error
        }

        // If the caller doesn't expect any data back, then return here so we don't fail during parsing
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        let parsedData = try decoder.decode(T.self, from: data)
        return parsedData
    }
}
