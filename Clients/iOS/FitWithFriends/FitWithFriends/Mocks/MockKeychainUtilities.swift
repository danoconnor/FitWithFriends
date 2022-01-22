//
//  MockKeychainUtilities.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockKeychainUtilities: KeychainUtilities {
    var return_error: KeychainError?

    var return_getKeychainItem: Codable?
    override func getKeychainItem<T: Codable>(accessGroup: String, service: String, account: String) -> Result<T, KeychainError> {
        if let item = return_getKeychainItem as? T {
            return .success(item)
        } else {
            return .failure(return_error ?? KeychainError.couldNotParseKeychainData)
        }
    }

    override func writeKeychainItem<T: Codable>(_ item: T, accessGroup: String, service: String, account: String, updateExistingItemIfNecessary: Bool) -> KeychainError? {
        return return_error
    }

    override func deleteKeychainItem(accessGroup: String, service: String, account: String) -> KeychainError? {
        return return_error
    }

    override func deleteAllItems(in accessGroup: String) -> KeychainError? {
        return return_error
    }
}
