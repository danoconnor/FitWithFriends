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
    private let homepageSheetViewModel: HomepageSheetViewModel
    private let pushNotificationManager: PushNotificationManager

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
         homepageSheetViewModel: HomepageSheetViewModel,
         pushNotificationManager: PushNotificationManager) {
        self.healthKitManager = healthKitManager
        self.homepageSheetViewModel = homepageSheetViewModel
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

    func dismiss() {
        homepageSheetViewModel.updateState(sheet: .permissionPrompt, state: false)
    }

    private func updateShouldShowPromptValue() {
        DispatchQueue.main.async {
            let shouldShowPrompt = self.shouldPromptForHealth || self.shouldPromptForNotifications
            self.homepageSheetViewModel.updateState(sheet: .permissionPrompt, state: shouldShowPrompt)
        }
    }
}
