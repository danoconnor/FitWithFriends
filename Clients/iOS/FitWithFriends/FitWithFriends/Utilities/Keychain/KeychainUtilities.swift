//
//  KeychainUtilities.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

public class KeychainUtilities {
    func getKeychainItem(accessGroup: String, service: String, account: String) -> Result<AnyObject, KeychainError> {
        let queryDictionary: [CFString: Any?] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrAccessGroup: getAccessGroupWithPrefix(accessGroup: accessGroup),
            kSecReturnData: kCFBooleanTrue,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(queryDictionary as CFDictionary, &result)

        if status != errSecSuccess {
            let error: KeychainError
            if status == errSecItemNotFound {
                error = .valueNotFound(key: account)
            } else {
                error = .generic(statusCode: status)
            }

            Logger.traceError(message: "Failed to query keychain for item. AccessGroup = \(accessGroup), Service = \(service), Account = \(account)", error: error)
            return .failure(error)
        }

        guard let returnedData = result as? Data else {
            Logger.traceError(message: "Got success code but no result was returned")
            return .failure(.couldNotParseKeychainData)
        }

        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: returnedData)
            let unarchivedData = unarchiver.decodeObject()
            unarchiver.finishDecoding()

            guard let dataToReturn = unarchivedData else {
                let error = KeychainError.couldNotParseKeychainData
                Logger.traceError(message: "Could not retrieve data from unarchiver", error: error)
                return .failure(error)
            }

            return .success(dataToReturn as AnyObject)
        } catch {
            Logger.traceError(message: "Failed to unarchive data returned from keychain", error: error)
            return .failure(.couldNotParseKeychainData)
        }
    }

    func writeKeychainItem(data: AnyObject, accessGroup: String, service: String, account: String, updateExistingItemIfNecessary: Bool) -> KeychainError? {
        // The dictionary that lets us find the target entry
        let queryDictionary: [CFString: Any?] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrAccessGroup: getAccessGroupWithPrefix(accessGroup: accessGroup)
        ]

        // Transform the given object into a standard format to write to the keychain
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encodeRootObject(data)
        archiver.finishEncoding()
        let encodedData = archiver.encodedData

        // Dictionary to use to create a new keychain item
        var addItemDictionary = queryDictionary
        addItemDictionary[kSecValueData] = encodedData

        var status = SecItemAdd(addItemDictionary as CFDictionary, nil)

        if status == errSecDuplicateItem, updateExistingItemIfNecessary {
            // Adding a new item failed, try to update the existing item instead
            // The second parameter is the attributes that we want to update, in this case the data attribute
            status = SecItemUpdate(queryDictionary as CFDictionary, [kSecValueData: encodedData] as CFDictionary)
        }

        if status != errSecSuccess {
            let error: KeychainError
            if status == errSecDuplicateItem {
                error = .keyAlreadyExists(key: account)
            } else {
                error = .generic(statusCode: status)
            }

            Logger.traceError(message: "Failed to add data to keychain. AccessGroup = \(accessGroup), Service = \(service), Account = \(account)", error: error)
            return error
        }

        return nil
    }

    func deleteKeychainItem(accessGroup: String, service: String, account: String) -> KeychainError? {
        let queryDictionary: [CFString: Any?] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrAccessGroup: getAccessGroupWithPrefix(accessGroup: accessGroup)
        ]

        let status = SecItemDelete(queryDictionary as CFDictionary)

        // If the item was not found, then we don't need to return an error
        if status != errSecSuccess, status != errSecItemNotFound {
            let error = KeychainError.generic(statusCode: status)
            Logger.traceError(message: "Failed to delete keychain item. AccessGroup = \(accessGroup), Service = \(service), Account = \(account)", error: error)
            return error
        }

        return nil
    }

    func deleteAllItems() -> Error? {
        let queryDictionary: [CFString: Any?] = [
            kSecClass: kSecClassGenericPassword
        ]

        let status = SecItemDelete(queryDictionary as CFDictionary)

        // If the item was not found, then we don't need to return an error
        if status != errSecSuccess, status != errSecItemNotFound {
            let error = KeychainError.generic(statusCode: status)
            Logger.traceError(message: "Failed to delete all keychain items", error: error)
            return error
        }

        return nil
    }

    private func getAccessGroupWithPrefix(accessGroup: String) -> String {
        // Don't re-add the prefix if our caller has already added it
        if accessGroup.contains(SecretConstants.keychainPrefix) {
            return accessGroup
        }

        return "\(SecretConstants.keychainPrefix).\(accessGroup)"
    }
}
