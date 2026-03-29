//
//  MockPushNotificationService.swift
//  FitWithFriends
//

import Foundation

public class MockPushNotificationService: IPushNotificationService {
    public init() {}

    public var param_registerPushToken_pushToken: String?
    public var param_registerPushToken_appInstallId: String?
    public var return_registerPushToken_error: Error?
    public var registerPushTokenCallCount = 0

    public func registerPushToken(_ pushToken: String, appInstallId: String) async throws {
        registerPushTokenCallCount += 1
        param_registerPushToken_pushToken = pushToken
        param_registerPushToken_appInstallId = appInstallId

        if let error = return_registerPushToken_error {
            throw error
        }
    }
}
