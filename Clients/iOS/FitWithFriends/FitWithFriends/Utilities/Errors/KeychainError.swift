//
//  KeychainError.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

public enum KeychainError: LocalizedError {
    case valueNotFound(key: String)
    case keyAlreadyExists(key: String)
    case generic(statusCode: OSStatus)
    case couldNotParseKeychainData
    case couldNotFormatDataForKeychain

    public var message: String {
        return description
    }

    public var description: String {
        switch self {
        case let .valueNotFound(key):
            return "Value not found for key \(key)"
        case let .keyAlreadyExists(key):
            return "Key already exists: \(key)"
        case let .generic(statusCode):
            return "Generic error with OSStatus code \(statusCode)"
        case .couldNotParseKeychainData:
            return "Could not parse keychain data"
        case .couldNotFormatDataForKeychain:
            return "Could not format data for keychain"
        }
    }
}
