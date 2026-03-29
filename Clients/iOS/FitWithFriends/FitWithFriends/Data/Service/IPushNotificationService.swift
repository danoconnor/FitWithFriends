//
//  IPushNotificationService.swift
//  FitWithFriends
//

import Foundation

public protocol IPushNotificationService {
    func registerPushToken(_ pushToken: String, appInstallId: String) async throws
}
