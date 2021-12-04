//
//  KeychainUtilities.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

public class KeychainUtilities {
    func getKeychainItem<T: Codable>(accessGroup: String, service: String, account: String) -> Result<T, KeychainError> {
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
            // Objects are converted to JSON when writing to the keychain so we'll treat the retuned data as JSON here
            let decodedObject = try JSONDecoder.fwfDefaultDecoder.decode(T.self, from: returnedData)
            return .success(decodedObject)
        } catch {
            print(error.localizedDescription)
            Logger.traceError(message: "Failed to unarchive data returned from keychain", error: error)
            return .failure(.encodingError(innerError: error))
        }
    }

    func writeKeychainItem<T: Codable>(_ item: T, accessGroup: String, service: String, account: String, updateExistingItemIfNecessary: Bool) -> KeychainError? {
        // The dictionary that lets us find the target entry
        let queryDictionary: [CFString: Any?] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrAccessGroup: getAccessGroupWithPrefix(accessGroup: accessGroup)
        ]

        // Convert all keychain items to JSON
        let jsonData: Data
        do {
            jsonData = try JSONEncoder.fwfDefaultEncoder.encode(item)
        } catch {
            return .encodingError(innerError: error)
        }

        // Dictionary to use to create a new keychain item
        var addItemDictionary = queryDictionary
        addItemDictionary[kSecValueData] = jsonData

        var status = SecItemAdd(addItemDictionary as CFDictionary, nil)

        if status == errSecDuplicateItem, updateExistingItemIfNecessary {
            // Adding a new item failed, try to update the existing item instead
            // The second parameter is the attributes that we want to update, in this case the data attribute
            status = SecItemUpdate(queryDictionary as CFDictionary, [kSecValueData: jsonData] as CFDictionary)
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

    func deleteAllItems(in accessGroup: String) -> Error? {
        let queryDictionary: [CFString: Any?] = [
            kSecAttrAccessGroup: getAccessGroupWithPrefix(accessGroup: accessGroup),
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
