//
//  TodaySummaryViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import Combine
import Foundation
import HealthKit

class TodaySummaryViewModel: ObservableObject {
    private let healthKitManager: HealthKitManager

    @Published var todayActivitySummary: HKActivitySummary?

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager

        healthKitManager.getCurrentActivitySummary { [weak self] summary in
            DispatchQueue.main.async {
                self?.todayActivitySummary = summary
            }
        }
    }
}
