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

    @Published private(set) var shouldPromptForHealth: Bool {
        didSet {
            updateShouldShowPromptValue()
        }
    }

    init(healthKitManager: HealthKitManager,
         homepageSheetViewModel: HomepageSheetViewModel) {
        self.healthKitManager = healthKitManager
        self.homepageSheetViewModel = homepageSheetViewModel

        shouldPromptForHealth = healthKitManager.shouldPromptUser

        updateShouldShowPromptValue()
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
            self.homepageSheetViewModel.updateState(sheet: .permissionPrompt, state: self.shouldPromptForHealth)
        }
    }
}
