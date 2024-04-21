//
//  MockKeychainUtilities.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockKeychainUtilities: IKeychainUtilities {
    public init() {}

    var return_error: KeychainError?

    var return_getKeychainItem: Codable?
    public func getKeychainItem<T: Codable>(accessGroup: String, service: String, account: String) throws -> T {
        if let item = return_getKeychainItem as? T {
            return item
        } else {
            throw return_error ?? KeychainError.couldNotParseKeychainData
        }
    }

    public func writeKeychainItem<T: Codable>(_ item: T, accessGroup: String, service: String, account: String, updateExistingItemIfNecessary: Bool) throws {
        if let error = return_error {
            throw error
        }
    }

    public func deleteKeychainItem(accessGroup: String, service: String, account: String) throws {
        if let error = return_error {
            throw error
        }
    }

    public func deleteAllItems(in accessGroup: String) throws {
        if let error = return_error {
            throw error
        }
    }
}
