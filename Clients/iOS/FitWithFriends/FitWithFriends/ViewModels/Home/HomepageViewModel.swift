//
//  TodaySummaryViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import Combine
import Foundation
import HealthKit

class HomepageViewModel: ObservableObject {
    private let competitionManager: CompetitionManager
    private let healthKitManager: HealthKitManager

    @Published var todayActivitySummary: HKActivitySummary?

    @Published var currentCompetition: CompetitionOverview?
    private var competitionLoadListener: AnyCancellable?

    init(competitionManager: CompetitionManager, healthKitManager: HealthKitManager) {
        self.competitionManager = competitionManager
        self.healthKitManager = healthKitManager

        healthKitManager.getCurrentActivitySummary { [weak self] summary in
            DispatchQueue.main.async {
                self?.todayActivitySummary = summary
            }
        }

        // Need to hold a reference to this, otherwise the sink callback will never be invoked
        competitionLoadListener = competitionManager.$competitionOverviews.sink { [weak self] newValue in
            DispatchQueue.main.async {
                self?.currentCompetition = newValue.first?.value
            }
        }
    }
}
