//
//  JSONDecoder+Extension.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/4/21.
//

import Foundation

extension JSONDecoder {
    /// Returns a JSONDecoder with the dateDecodingStrategy set to .isoFormatter
    /// This is the configuration that we want in most places in our app
    static var fwfDefaultDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.isoFormatter)

        return decoder
    }
}
