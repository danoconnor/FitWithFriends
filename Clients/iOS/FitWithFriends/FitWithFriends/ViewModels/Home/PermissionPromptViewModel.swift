//
//  PermissionPromptViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/20.
//

import Combine
import Foundation

class PermissionPromptViewModel: ObservableObject {
    private let healthKitManager: HealthKitManager
    private let pushNotificationManager: PushNotificationManager

    @Published var shouldShowPermissionPrompt: Bool = false

    @Published private(set) var shouldPromptForNotifications: Bool {
        didSet {
            updateShouldShowPromptValue()
        }
    }


    @Published private(set) var shouldPromptForHealth: Bool {
        didSet {
            updateShouldShowPromptValue()
        }
    }

    init(healthKitManager: HealthKitManager,
         pushNotificationManager: PushNotificationManager) {
        self.healthKitManager = healthKitManager
        self.pushNotificationManager = pushNotificationManager

        shouldPromptForNotifications = pushNotificationManager.shouldPromptUser
        shouldPromptForHealth = healthKitManager.shouldPromptUser

        updateShouldShowPromptValue()
    }

    func requestNotificationPermission() {
        pushNotificationManager.promptForNotificationPermission { [weak self] in
            DispatchQueue.main.async {
                self?.shouldPromptForNotifications = false
            }
        }
    }

    func requestHealthPermission() {
        healthKitManager.requestHealthKitPermission { [weak self] in
            DispatchQueue.main.async {
                self?.shouldPromptForHealth = false
            }
        }
    }

    private func updateShouldShowPromptValue() {
        DispatchQueue.main.async {
            self.shouldShowPermissionPrompt = self.shouldPromptForHealth || self.shouldPromptForNotifications
        }
    }
}
