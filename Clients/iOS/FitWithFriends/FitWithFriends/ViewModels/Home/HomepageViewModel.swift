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
    private let authenticationManager: AuthenticationManager
    private let competitionManager: CompetitionManager
    private let healthKitManager: HealthKitManager

    @Published var todayActivitySummary: ActivitySummary?
    @Published var currentCompetitions: [CompetitionOverview]?

    private var competitionLoadListener: AnyCancellable?

    init(authenticationManager: AuthenticationManager, competitionManager: CompetitionManager, healthKitManager: HealthKitManager) {
        self.authenticationManager = authenticationManager
        self.competitionManager = competitionManager
        self.healthKitManager = healthKitManager

        // Fire and forget the activity summary refresh
        Task.detached { await self.refreshTodayActivitySummary() }

        // Need to hold a reference to this, otherwise the sink callback will never be invoked
        competitionLoadListener = competitionManager.$competitionOverviews.sink { [weak self] newValue in
            DispatchQueue.main.async {
                self?.currentCompetitions = newValue.map { $0.value }
                    .sorted { $0 < $1 }
            }
        }
    }

    func refreshData() async {
        let activitySummaryTask = Task { await self.refreshTodayActivitySummary() }
        let competitionTask = Task { await self.competitionManager.refreshCompetitionOverviews() }

        await activitySummaryTask.value
        await competitionTask.value
    }

    func logout() {
        authenticationManager.logout()
    }

    private func refreshTodayActivitySummary() async {
        return await withCheckedContinuation { continuation in
            healthKitManager.getCurrentActivitySummary { summary in
                let activitySummary: ActivitySummary?
                if let summary = summary {
                    activitySummary = ActivitySummary(activitySummary: summary)
                } else {
                    // Couldn't get the activity summary for today
                    // This may be expected if there is no data for today yet, or
                    // if the user has not given access to the health data
                    activitySummary = ActivitySummary(date: Date())
                }

                DispatchQueue.main.async {
                    self.todayActivitySummary = activitySummary
                    continuation.resume()
                }
            }
        }

    }
}
