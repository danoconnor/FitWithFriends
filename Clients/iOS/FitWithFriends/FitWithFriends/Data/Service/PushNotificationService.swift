//
//  PushNotificationService.swift
//  FitWithFriends
//

import Foundation

public class PushNotificationService: ServiceBase, IPushNotificationService {
    public func registerPushToken(_ pushToken: String, appInstallId: String) async throws {
        let _: EmptyResponse = try await makeRequestWithUserAuthentication(
            url: "\(serverEnvironmentManager.baseUrl)/pushNotifications/register",
            method: .post,
            body: RegisterPushTokenRequest(pushToken: pushToken, platform: 1, appInstallId: appInstallId)
        )
    }
}

private struct RegisterPushTokenRequest: Encodable {
    let pushToken: String
    let platform: Int
    let appInstallId: String
}
