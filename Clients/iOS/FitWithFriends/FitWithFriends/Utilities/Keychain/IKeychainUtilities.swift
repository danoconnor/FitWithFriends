//
//  IKeychainUtilities.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/10/24.
//

import Foundation

/// Handles reading and writing data from the keychain
public protocol IKeychainUtilities {

    /// Gets a keychain item and decodes it to the requested type T
    /// - Parameters:
    ///   - accessGroup: The access group to use in the keychain lookup
    ///   - service: The service to use in the keychain lookup
    ///   - account: The account to use in the keychain lookup
    /// - Returns: The keychain data decoded into the type T
    func getKeychainItem<T: Codable>(accessGroup: String, service: String, account: String) throws -> T
    
    /// Writes the given item to the keychain
    /// - Parameters:
    ///   - item: The item to store in the keychain
    ///   - accessGroup: The access group to use for the keychain item
    ///   - service: The service to use for the keychain item
    ///   - account: The account to use for the keychain item
    ///   - updateExistingItemIfNecessary: True if we should overwrite the existing item on conflict, or false if we should throw an error if there is already an existing item
    func writeKeychainItem<T: Codable>(_ item: T, accessGroup: String, service: String, account: String, updateExistingItemIfNecessary: Bool) throws

    /// Deletes the target keychain item, if it exists
    /// - Parameters:
    ///   - accessGroup: The access group to use in the keychain lookup
    ///   - service: The service to use in the keychain lookup
    ///   - account: The account to use in the keychain lookup
    func deleteKeychainItem(accessGroup: String, service: String, account: String) throws
    
    /// Delete all the keychain items in the given access group
    /// - Parameter accessGroup: The access group to delete all keychain items from
    func deleteAllItems(in accessGroup: String) throws
}
