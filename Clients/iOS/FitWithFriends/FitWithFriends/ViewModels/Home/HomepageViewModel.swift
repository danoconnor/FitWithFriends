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

    @Published var loadedActivitySummary: Bool
    @Published var todayActivitySummary: ActivitySummary?

    @Published var currentCompetitions: [CompetitionOverview]?

    private var competitionLoadListener: AnyCancellable?

    init(authenticationManager: AuthenticationManager, competitionManager: CompetitionManager, healthKitManager: HealthKitManager) {
        self.authenticationManager = authenticationManager
        self.competitionManager = competitionManager
        self.healthKitManager = healthKitManager

        loadedActivitySummary = false

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
                    // Couldn't get activity summary for today - check if it is because there is no data for today or if we don't have access

                    let lastKnownCalorieGoal = self.healthKitManager.lastKnownCalorieGoal
                    let lastKnownExerciseGoal = self.healthKitManager.lastKnownExerciseGoal
                    let lastKnownStandGoal = self.healthKitManager.lastKnownStandGoal

                    if lastKnownCalorieGoal > 0, lastKnownExerciseGoal > 0, lastKnownStandGoal > 0 {
                        // We have existing known goals so we probably have health data access
                        // Create an activity summary with no data
                        activitySummary = ActivitySummary(date: Date(), calorieGoal: lastKnownCalorieGoal, exerciseGoal: lastKnownExerciseGoal, standGoal: lastKnownStandGoal)
                    } else {
                        // We don't have existing goals, so we probably don't have health data access
                        activitySummary = nil
                    }
                }

                DispatchQueue.main.async {
                    self.todayActivitySummary = activitySummary
                    self.loadedActivitySummary = true
                    continuation.resume()
                }
            }
        }

    }
}
