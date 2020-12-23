//
//  Encodable+Extension.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/23/20.
//

import Foundation

extension Encodable {
  var xtDictionary: [String: String]? {
    guard let data = try? JSONEncoder().encode(self) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: String] }
  }
}
