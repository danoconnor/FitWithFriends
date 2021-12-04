//
//  JSONEncoder+Extension.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/4/21.
//

import Foundation

extension JSONEncoder {
    /// Returns a JSONEncoder with the dateEncodingStrategy set to .iso8601
    /// This is the configuration that we want in most places in our app
    static var fwfDefaultEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(DateFormatter.isoFormatter)

        return encoder
    }
}
