//
//  AppleAuthenticationManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/26/22.
//

import AuthenticationServices
import Foundation

public class AppleAuthenticationManager: NSObject, IAppleAuthenticationManager {
    public weak var authenticationDelegate: AppleAuthenticationDelegate?

    private let authenticationService: IAuthenticationService
    private let keychainUtilities: IKeychainUtilities
    private let serverEnvironmentManager: ServerEnvironmentManager
    private let userService: IUserService

    private let appleIdProvider: ASAuthorizationAppleIDProvider

    private static let appleUserKeychainGroup = "com.danoconnor.FitWithFriends"
    private static let appleUserKeychainService = "com.danoconnor.FitWithFriends"
    private static let appleUserKeychainAccount = "appleUserId"

    // The user display name provided via custom UI and used to create a new user
    private var userProvidedName: PersonNameComponents?

    public init(authenticationService: IAuthenticationService,
                keychainUtilities: IKeychainUtilities,
                serverEnvironmentManager: ServerEnvironmentManager,
                userService: IUserService) {
        self.authenticationService = authenticationService
        self.keychainUtilities = keychainUtilities
        self.serverEnvironmentManager = serverEnvironmentManager
        self.userService = userService

        appleIdProvider = ASAuthorizationAppleIDProvider()
    }


    /// Acquires a token using Sign In With Apple
    /// - Parameters:
    ///   - presentationDelegate: The delegate to use for Sign In With Apple.
    ///   - userProvidedName: Optional user-provided display name. This is used in edge cases where Apple does not provide a name during account creation.
    public func beginAppleLogin(
        presentationDelegate: ASAuthorizationControllerPresentationContextProviding,
        userProvidedName: PersonNameComponents? = nil) {
        self.userProvidedName = userProvidedName

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
            guard let asCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                let credentialType = String(describing: type(of: authorization.credential))
                self?.authenticationDelegate?.authenticationCompleted(result: .failure(AppleAuthenticationError.unexpectedCredentialType(credentialType)))
                return
            }

            do {
                let appleAuthorizationCredential = try AppleAuthorizationCredential(appleIdCredential: asCredential)
                await self?.handleAuthorization(with: appleAuthorizationCredential)
            } catch {
                self?.authenticationDelegate?.authenticationCompleted(result: .failure(error))
                return
            }
        }
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Logger.traceError(message: "Received error from Apple authorization controller", error: error)
        authenticationDelegate?.authenticationCompleted(result: .failure(error))
    }

    // Fileprivate to allow unit testing
    fileprivate func handleAuthorization(with appleIdCredential: AppleAuthorizationCredential) async {
        var userId = appleIdCredential.userId

//        if serverEnvironmentManager.isLocalTesting {
//            // This value is hardcoded in our local database setup script (SetingTestData.sql)
//            // Local server builds skip Apple idToken validation so we can mock the userId here
//            Logger.traceWarning(message: "Overriding Apple userId to hardcoded value")
//            userId = "abcdef1234567890"
//        }

        // Apple will only provide the user's name when they first setup the account
        // Their docs say that the fullName property should be nil, but it appears to be
        // a not-nil object with nil/empty strings for all properties. So we need to check
        // the description to see if there's actually any data in there
        if let userName = appleIdCredential.displayName,
            userName.description.count > 0 {

            do {
                try await createNewUser(userId: userId,
                                        userName: userName,
                                        idToken: appleIdCredential.idToken,
                                        authorizationCode: appleIdCredential.authorizationCode)
            } catch {
                // Swallow the error here because it is possible that the user already exists and we should continue to try to acquire a token
                Logger.traceError(message: "Failed to create user as part of auth flow. Ignoring error and attempting auth", error: error)
            }
        }

        Logger.traceInfo(message: "Attempting to fetch token for user with ID \(appleIdCredential.userId)")
        do {
            let token = try await authenticationService.getTokenFromAppleId(userId: userId,
                                                                            idToken: appleIdCredential.idToken,
                                                                            authorizationCode: appleIdCredential.authorizationCode)
            authenticationDelegate?.authenticationCompleted(result: .success(token))
        } catch {
            if let httpError = error as? HttpError,
               httpError.errorDetails?.fwfErrorCode == .userNotFound {

                if let userProvidedName = userProvidedName {
                    Logger.traceInfo(message: "User has provided display name, creating user then retrying auth")
                    do {
                        try await createNewUser(
                            userId: userId,
                            userName: userProvidedName,
                            idToken: appleIdCredential.idToken,
                            authorizationCode: appleIdCredential.authorizationCode)
                        await handleAuthorization(with: appleIdCredential)
                    } catch {
                        Logger.traceError(message: "Failed to create user when a user doesn't exist", error: error)
                        authenticationDelegate?.authenticationCompleted(result: .failure(error))
                    }
                } else {
                    Logger.traceInfo(message: "Need to get display name from user")
                    authenticationDelegate?.needUserInformation()
                }

                return
            }

            authenticationDelegate?.authenticationCompleted(result: .failure(error))
        }
    }

    private func createNewUser(userId: String, userName: PersonNameComponents, idToken: String, authorizationCode: String) async throws {
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
            Logger.traceError(message: "Failed to create user for ID \(userId)", error: error)
            throw error
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
