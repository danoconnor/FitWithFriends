//
//  TodaySummaryViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import Combine
import Foundation
import HealthKit

public class HomepageViewModel: ObservableObject {
    private let authenticationManager: IAuthenticationManager
    private let competitionManager: ICompetitionManager
    private let healthKitManager: IHealthKitManager
    private let subscriptionManager: ISubscriptionManager

    @Published var loadedActivitySummary: Bool
    @Published var todayActivitySummary: ActivitySummary?

    @Published var currentCompetitions: [CompetitionOverview]?
    @Published var publicCompetitions: [PublicCompetition]?
    @Published var isUserPro: Bool = false

    private var competitionLoadListener: AnyCancellable?
    private var publicCompetitionLoadListener: AnyCancellable?
    private var proStatusListener: AnyCancellable?

    init(authenticationManager: IAuthenticationManager,
         competitionManager: ICompetitionManager,
         healthKitManager: IHealthKitManager,
         subscriptionManager: ISubscriptionManager) {
        self.authenticationManager = authenticationManager
        self.competitionManager = competitionManager
        self.healthKitManager = healthKitManager
        self.subscriptionManager = subscriptionManager

        loadedActivitySummary = false

        // Fire and forget the activity summary refresh
        Task.detached { await self.refreshTodayActivitySummary() }

        // Need to hold a reference to this, otherwise the sink callback will never be invoked
        competitionLoadListener = competitionManager.competitionOverviewsPublisher.sink { [weak self] newValue in
            DispatchQueue.main.async {
                self?.currentCompetitions = newValue.map { $0.value }
                    .sorted { $0 < $1 }
            }
        }

        publicCompetitionLoadListener = competitionManager.publicCompetitionsPublisher.sink { [weak self] newValue in
            DispatchQueue.main.async {
                self?.publicCompetitions = newValue
            }
        }

        proStatusListener = subscriptionManager.isUserProPublisher.sink { [weak self] newValue in
            DispatchQueue.main.async {
                self?.isUserPro = newValue
            }
        }

        // Check subscription status on init
        Task.detached { await subscriptionManager.checkSubscriptionStatus() }
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
                DispatchQueue.main.async {
                    self.todayActivitySummary = summary
                    self.loadedActivitySummary = true
                    continuation.resume()
                }
            }
        }

    }
}
