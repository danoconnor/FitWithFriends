//
//  FWFErrorDetails.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/22.
//

import Foundation

class FWFErrorDetails: Decodable {
    /// Context provided by the service about the scenario that threw the error
    let context: String

    /// The raw error message that was thrown
    /// May be nil
    let errorDetails: String?

    /// A custom error code that maps to our known errors
    /// May be nil
    let customErrorCode: Int?

    /// The custom error code, parsed into a more usable enum value
    var fwfErrorCode: FWFErrorCode {
        if let rawCode = customErrorCode,
           let code = FWFErrorCode(rawValue: rawCode) {
            return code
        }

        return .unknown
    }
}
