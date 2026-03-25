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
    public var getKeychainItemCallCount = 0
    public func getKeychainItem<T: Codable>(accessGroup: String, service: String, account: String) throws -> T {
        getKeychainItemCallCount += 1
        if let item = return_getKeychainItem as? T {
            return item
        } else {
            throw return_error ?? KeychainError.couldNotParseKeychainData
        }
    }

    public var writeKeychainItemCallCount = 0
    public var writeKeychainItemLastValueSet: Codable? = nil
    public func writeKeychainItem<T: Codable>(_ item: T, accessGroup: String, service: String, account: String, updateExistingItemIfNecessary: Bool) throws {
        writeKeychainItemCallCount += 1
        writeKeychainItemLastValueSet = item
        if let error = return_error {
            throw error
        }
    }

    public var deleteKeychainItemCallCount = 0
    public func deleteKeychainItem(accessGroup: String, service: String, account: String) throws {
        deleteKeychainItemCallCount += 1
        if let error = return_error {
            throw error
        }
    }

    public var deleteAllItemsCallCount = 0
    public func deleteAllItems(in accessGroup: String) throws {
        deleteAllItemsCallCount += 1
        if let error = return_error {
            throw error
        }
    }
}
