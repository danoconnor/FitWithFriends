//
//  TodaySummaryViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import Combine
import Foundation
import HealthKit

@MainActor
public class HomepageViewModel: ObservableObject {
    private let authenticationManager: IAuthenticationManager
    private let competitionManager: ICompetitionManager
    private let healthKitManager: IHealthKitManager
    private let subscriptionManager: ISubscriptionManager
    private let userService: IUserService

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
         subscriptionManager: ISubscriptionManager,
         userService: IUserService) {
        self.authenticationManager = authenticationManager
        self.competitionManager = competitionManager
        self.healthKitManager = healthKitManager
        self.subscriptionManager = subscriptionManager
        self.userService = userService

        loadedActivitySummary = false

        // Fire and forget the activity summary refresh
        Task.detached { await self.refreshTodayActivitySummary() }

        // Need to hold a reference to this, otherwise the sink callback will never be invoked
        competitionLoadListener = competitionManager.competitionOverviewsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.currentCompetitions = newValue.map { $0.value }
                    .sorted { $0 < $1 }
            }

        publicCompetitionLoadListener = competitionManager.publicCompetitionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.publicCompetitions = newValue
                    .filter { !$0.isUserMember && $0.endDate > Date() } // If the user is a member, it will be listed in currentCompetitions
            }

        proStatusListener = subscriptionManager.isUserProPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.isUserPro = newValue
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

    func deleteAccount() async -> Bool {
        do {
            try await userService.deleteAccount()
            authenticationManager.logout()
            return true
        } catch {
            Logger.traceError(message: "Failed to delete account", error: error)
            return false
        }
    }

    private func refreshTodayActivitySummary() async {
        let summary: ActivitySummary? = await withCheckedContinuation { continuation in
            healthKitManager.getCurrentActivitySummary { summary in
                continuation.resume(returning: summary)
            }
        }
        todayActivitySummary = summary
        loadedActivitySummary = true
    }
}
