//
//  Encodable+Extension.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/23/20.
//

import Foundation

extension Encodable {
  var xtDictionary: [String: String]? {
    do {
        let encodedData = try JSONEncoder.fwfDefaultEncoder.encode(self)
        let jsonData = try JSONSerialization.jsonObject(with: encodedData, options: .allowFragments)

        guard let anyDict = jsonData as? [String: Any] else { return nil }
        return anyDict.mapValues { String(describing: $0) }
    } catch {
        Logger.traceError(message: "Failed to get dictionary for codable type \(type(of: self))", error: error)
        return nil
    }
  }
}
