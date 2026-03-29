//
//  MockPushNotificationManager.swift
//  FitWithFriends
//

import Foundation

public class MockPushNotificationManager: IPushNotificationManager {
    public init() {}

    public var requestPushPermissionsAndRegisterCallCount = 0
    public func requestPushPermissionsAndRegister() {
        requestPushPermissionsAndRegisterCallCount += 1
    }

    public var param_handleDeviceToken: Data?
    public var handleDeviceTokenCallCount = 0
    public func handleDeviceToken(_ tokenData: Data) {
        handleDeviceTokenCallCount += 1
        param_handleDeviceToken = tokenData
    }
}
