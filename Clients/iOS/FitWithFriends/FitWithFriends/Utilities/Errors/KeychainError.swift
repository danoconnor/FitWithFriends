//
//  KeychainError.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

enum KeychainError: LocalizedError, CustomStringConvertible {
    case valueNotFound(key: String)
    case keyAlreadyExists(key: String)
    case generic(statusCode: OSStatus)
    case couldNotParseKeychainData
    case encodingError(innerError: Error)

    public var errorDescription: String? {
        return description
    }

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
        case let .encodingError(innerError):
            return "Could not encode data. Inner error: \(innerError.localizedDescription)"
        }
    }
}
