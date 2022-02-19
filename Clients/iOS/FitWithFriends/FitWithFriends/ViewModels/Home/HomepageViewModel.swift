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

    @Published var todayActivitySummary: ActivitySummary?
    @Published var currentCompetitions: [CompetitionOverview]?

    private var competitionLoadListener: AnyCancellable?

    init(competitionManager: CompetitionManager, healthKitManager: HealthKitManager) {
        self.competitionManager = competitionManager
        self.healthKitManager = healthKitManager

        // Fire and forget the activity summary refresh
        let _ = Task { await self.refreshTodayActivitySummary() }

        // Need to hold a reference to this, otherwise the sink callback will never be invoked
        competitionLoadListener = competitionManager.$competitionOverviews.sink { [weak self] newValue in
            DispatchQueue.main.async {
                self?.currentCompetitions = newValue.map { $0.value }
            }
        }
    }

    func refreshData() async {
        let activitySummaryTask = Task { await self.refreshTodayActivitySummary() }
        let competitionTask = Task { await self.competitionManager.refreshCompetitionOverviews() }

        await activitySummaryTask.value
        await competitionTask.value
    }

    private func refreshTodayActivitySummary() async {
        return await withCheckedContinuation { continuation in
            healthKitManager.getCurrentActivitySummary { summary in
                guard let summary = summary else {
                    continuation.resume()
                    return
                }

                DispatchQueue.main.async {
                    self.todayActivitySummary = ActivitySummary(activitySummary: summary)
                    continuation.resume()
                }
            }
        }

    }
}
