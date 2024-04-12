//
//  AppleAuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/26/22.
//

import AuthenticationServices
import Foundation

public protocol AppleAuthenticationDelegate: AnyObject {
    func authenticationCompleted(result: Result<Token, Error>)
}

public class AppleAuthenticationManager: NSObject {
    public weak var authenticationDelegate: AppleAuthenticationDelegate?

    private let authenticationService: IAuthenticationService
    private let keychainUtilities: IKeychainUtilities
    private let userService: IUserService

    private let appleIdProvider: ASAuthorizationAppleIDProvider

    private static let appleUserKeychainGroup = "com.danoconnor.FitWithFriends"
    private static let appleUserKeychainService = "com.danoconnor.FitWithFriends"
    private static let appleUserKeychainAccount = "appleUserId"

    public init(authenticationService: IAuthenticationService,
         keychainUtilities: IKeychainUtilities,
         userService: IUserService) {
        self.authenticationService = authenticationService
        self.keychainUtilities = keychainUtilities
        self.userService = userService

        appleIdProvider = ASAuthorizationAppleIDProvider()
    }

    public func beginAppleLogin(presentationDelegate: ASAuthorizationControllerPresentationContextProviding) {
        let request = appleIdProvider.createRequest()
        request.requestedScopes = [.fullName]

        do {
            let appleUserId: String = try keychainUtilities.getKeychainItem(accessGroup: AppleAuthenticationManager.appleUserKeychainGroup,
                                                                            service: AppleAuthenticationManager.appleUserKeychainService,
                                                                            account: AppleAuthenticationManager.appleUserKeychainAccount)

            request.user = appleUserId
        } catch {
            // Not a blocking error, we can continue the login process without a prepopulated userId
            Logger.traceWarning(message: "Could not get userId out of keychain. Error: \(error.localizedDescription)")
        }

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = presentationDelegate

        controller.performRequests()
    }

    public func isAppleAccountValid() -> Bool {
        var accountIsValid = true

        // Get the last known Apple User ID from the keychain
        let userId: String
        do {
            userId = try keychainUtilities.getKeychainItem(accessGroup: AppleAuthenticationManager.appleUserKeychainGroup,
                                                           service: AppleAuthenticationManager.appleUserKeychainService,
                                                           account: AppleAuthenticationManager.appleUserKeychainAccount)
        } catch {
            Logger.traceInfo(message: "Could not get Apple user ID from keychain. Error: \(error.localizedDescription)")

            // Return true if we don't have an Apple account setup
            return accountIsValid
        }

        let dispatchSemaphore = DispatchSemaphore(value: 0)
        appleIdProvider.getCredentialState(forUserID: userId) { [weak self] credentialState, error in
            defer {
                dispatchSemaphore.signal()
            }

            guard error == nil else {
                Logger.traceError(message: "Could not get credential state for userId \(userId)", error: error)
                return
            }

            Logger.traceInfo(message: "Got Apple credential state: \(credentialState.rawValue)")
            accountIsValid = credentialState == .authorized

            if !accountIsValid {
                // Remove our cached Apple user ID if it is no longer valid
                do {
                    try self?.keychainUtilities.deleteKeychainItem(accessGroup: AppleAuthenticationManager.appleUserKeychainGroup,
                                                                   service: AppleAuthenticationManager.appleUserKeychainService,
                                                                   account: AppleAuthenticationManager.appleUserKeychainAccount)

                    Logger.traceInfo(message: "Successfully removed Apple user ID from keychain because it is no longer valid")
                } catch {
                    Logger.traceError(message: "Could not remove Apple user ID from keychain", error: error)
                }
            }
        }

        dispatchSemaphore.wait()
        return accountIsValid
    }
}

extension AppleAuthenticationManager: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Logger.traceInfo(message: "Got Apple authorization controller response")

        Task.detached { [weak self] in
            await self?.handleAuthorization(authorization)
        }
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Logger.traceError(message: "Received error from Apple authorization controller", error: error)
        authenticationDelegate?.authenticationCompleted(result: .failure(error))
    }

    private func handleAuthorization(_ authorization: ASAuthorization) async {
        guard let appleIdCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            let credentialType = String(describing: type(of: authorization.credential))
            authenticationDelegate?.authenticationCompleted(result: .failure(AppleAuthenticationError.unexpectedCredentialType(credentialType)))
            return
        }
        
        guard let idTokenData = appleIdCredential.identityToken,
              let idToken = String(data: idTokenData, encoding: .utf8),
              let authorizationCodeData = appleIdCredential.authorizationCode,
              let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) else {
            let error: AppleAuthenticationError = appleIdCredential.identityToken == nil ? .noTokenReturned : .noAuthorizationReturned
            authenticationDelegate?.authenticationCompleted(result: .failure(error))
            return
        }

        // Apple will only provide the user's name when they first setup the account
        // Their docs say that the fullName property should be nil, but it appears to be
        // a not-nil object with nil/empty strings for all properties. So we need to check
        // the description to see if there's actually any data in there
        if let userName = appleIdCredential.fullName,
            userName.description.count > 0 {
            await createNewUser(userId: appleIdCredential.user,
                                userName: userName,
                                idToken: idToken,
                                authorizationCode: authorizationCode)
        }

        Logger.traceInfo(message: "Attempting to fetch token for user with ID \(appleIdCredential.user)")
        do {
            let token = try await authenticationService.getTokenFromAppleId(userId: appleIdCredential.user,
                                                                            idToken: idToken,
                                                                            authorizationCode: authorizationCode)
            authenticationDelegate?.authenticationCompleted(result: .success(token))
        } catch {
            authenticationDelegate?.authenticationCompleted(result: .failure(error))
        }
    }

    private func createNewUser(userId: String, userName: PersonNameComponents, idToken: String, authorizationCode: String) async {
        Logger.traceInfo(message: "Apple provided user name - creating new user with ID \(userId)")

        // Try to use nickname as the first name for more familiarity, if available
        do {
            try await userService.createUser(firstName: userName.nickname ?? userName.givenName ?? "",
                                             lastName: userName.familyName ?? "",
                                             userId: userId,
                                             idToken: idToken,
                                             authorizationCode: authorizationCode)

            Logger.traceVerbose(message: "Successfully created user with id \(userId)")
        } catch {
            // Don't throw if there is an error creating the user,
            // it's possible that the user already exists so we should continue
            // and attempt to get a token
            Logger.traceError(message: "Failed to create user for ID \(userId)", error: error)
            return
        }

        do {
            try keychainUtilities.writeKeychainItem(userId,
                                                    accessGroup: AppleAuthenticationManager.appleUserKeychainGroup,
                                                    service: AppleAuthenticationManager.appleUserKeychainService,
                                                    account: AppleAuthenticationManager.appleUserKeychainAccount,
                                                    updateExistingItemIfNecessary: false)

        } catch {
            Logger.traceError(message: "Failed to save Apple user ID to keychain", error: error)
            return
        }
    }
}
