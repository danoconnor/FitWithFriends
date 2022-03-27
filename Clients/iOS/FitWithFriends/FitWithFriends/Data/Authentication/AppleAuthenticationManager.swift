//
//  AppleAuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/26/22.
//

import AuthenticationServices
import Foundation

protocol AppleAuthenticationDelegate: AnyObject {
    func authenticationCompleted(result: Result<Token, Error>)
}

class AppleAuthenticationManager: NSObject {
    weak var authenticationDelegate: AppleAuthenticationDelegate?

    private let authenticationService: AuthenticationService
    private let keychainUtilities: KeychainUtilities
    private let userService: UserService

    private let appleIdProvider: ASAuthorizationAppleIDProvider

    private static let appleUserKeychainGroup = "com.danoconnor.FitWithFriends"
    private static let appleUserKeychainService = "com.danoconnor.FitWithFriends"
    private static let appleUserKeychainAccount = "appleUserId"

    init(authenticationService: AuthenticationService,
         keychainUtilities: KeychainUtilities,
         userService: UserService) {
        self.authenticationService = authenticationService
        self.keychainUtilities = keychainUtilities
        self.userService = userService

        appleIdProvider = ASAuthorizationAppleIDProvider()
    }

    func beginAppleLogin(presentationDelegate: ASAuthorizationControllerPresentationContextProviding) {
        let request = appleIdProvider.createRequest()
        request.requestedScopes = [.fullName]

        let appleUserIdResult: Result<String, KeychainError> = keychainUtilities.getKeychainItem(accessGroup: AppleAuthenticationManager.appleUserKeychainGroup,
                                                                                                 service: AppleAuthenticationManager.appleUserKeychainService,
                                                                                                 account: AppleAuthenticationManager.appleUserKeychainAccount)
        if let appleUserId = appleUserIdResult.xtSuccess {
            request.user = appleUserId
        }

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = presentationDelegate

        controller.performRequests()
    }

    func isAppleAccountValid() -> Bool {
        // Get the last known Apple User ID from the keychain
        let appleUserIdResult: Result<String, KeychainError> = keychainUtilities.getKeychainItem(accessGroup: AppleAuthenticationManager.appleUserKeychainGroup,
                                                                                                 service: AppleAuthenticationManager.appleUserKeychainService,
                                                                                                 account: AppleAuthenticationManager.appleUserKeychainAccount)

        var accountIsValid = true

        guard let userId = appleUserIdResult.xtSuccess else {
            Logger.traceInfo(message: "Could not get Apple user ID from keychain. Error: \(appleUserIdResult.xtError?.localizedDescription ?? "nil")")

            // Return true if we don't have an Apple account setup
            return accountIsValid
        }

        let dispatchSemaphore = DispatchSemaphore(value: 0)
        appleIdProvider.getCredentialState(forUserID: userId) { [weak self] credentialState, error in
            guard error == nil else {
                Logger.traceError(message: "Could not get credential state for userId \(userId)", error: error)
                return
            }

            // TODO: should we delete the user from the database if the user has deleted the Apple credential for our app?
            Logger.traceInfo(message: "Got Apple credential state: \(credentialState.rawValue)")
            accountIsValid = credentialState == .authorized

            if !accountIsValid {
                // Remove our cached Apple user ID if it is no longer valid
                let deleteError = self?.keychainUtilities.deleteKeychainItem(accessGroup: AppleAuthenticationManager.appleUserKeychainGroup,
                                                                             service: AppleAuthenticationManager.appleUserKeychainService,
                                                                             account: AppleAuthenticationManager.appleUserKeychainAccount)
                if let deleteError = deleteError {
                    Logger.traceError(message: "Could not remove Apple user ID from keychain", error: deleteError)
                } else {
                    Logger.traceInfo(message: "Successfully removed Apple user ID from keychain because it is no longer valid")
                }
            }

            dispatchSemaphore.signal()
        }

        dispatchSemaphore.wait()
        return accountIsValid
    }
}

extension AppleAuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Logger.traceInfo(message: "Got Apple authorization controller response")

        Task.detached { [weak self] in
            await self?.handleAuthorization(authorization)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Logger.traceError(message: "Received error from Apple authorization controller", error: error)
        authenticationDelegate?.authenticationCompleted(result: .failure(error))
    }

    private func handleAuthorization(_ authorization: ASAuthorization) async {
        guard let appleIdCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            let credentialType = String(describing: type(of: authorization.credential))
            authenticationDelegate?.authenticationCompleted(result: .failure(AppleAuthenticationError.unexpectedCredentialType(credentialType)))
            return
        }

        // Apple will only provide the user's name when they first setup the account
        if appleIdCredential.fullName != nil {
            await createNewUserWithCredential(appleIdCredential)
        }
        
        guard let idTokenData = appleIdCredential.identityToken,
              let idToken = String(data: idTokenData, encoding: .utf8),
              let authorizationCodeData = appleIdCredential.authorizationCode,
              let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) else {
            let error: AppleAuthenticationError = appleIdCredential.identityToken == nil ? .noTokenReturned : .noAuthorizationReturned
            authenticationDelegate?.authenticationCompleted(result: .failure(error))
            return
        }

        Logger.traceInfo(message: "Attempting to fetch token for user with ID \(appleIdCredential.user)")
        let tokenResult = await authenticationService.getTokenFromAppleId(userId: appleIdCredential.user,
                                                                          idToken: idToken,
                                                                          authorizationCode: authorizationCode)
        authenticationDelegate?.authenticationCompleted(result: tokenResult)
    }

    private func createNewUserWithCredential(_ appleIdCredential: ASAuthorizationAppleIDCredential) async {
        Logger.traceInfo(message: "Apple provided user name - creating new user with ID \(appleIdCredential.user)")

        let userName = appleIdCredential.fullName
        let createUserResult = await userService.createUser(firstName: userName?.nickname ?? "",
                                                            lastName: userName?.familyName ?? "",
                                                            userId: appleIdCredential.user)

        if let createUserError = createUserResult.xtError {
            // Don't throw if there is an error creating the user.
            // There could be a bug where we couldn't read the cached user ID from the keychain.
            // That would cause Apple to give us the same user information again as a "new user",
            // but user creation would fail due to duplicate user IDs
            Logger.traceError(message: "Failed to create user for ID \(appleIdCredential.user)", error: createUserError)
            return
        }

        let saveUserError = keychainUtilities.writeKeychainItem(appleIdCredential.user,
                                                                accessGroup: AppleAuthenticationManager.appleUserKeychainGroup,
                                                                service: AppleAuthenticationManager.appleUserKeychainService,
                                                                account: AppleAuthenticationManager.appleUserKeychainAccount,
                                                                updateExistingItemIfNecessary: false)

        if let saveUserError = saveUserError {
            Logger.traceError(message: "Failed to save Apple user ID to keychain", error: saveUserError)
            return
        }
    }
}
