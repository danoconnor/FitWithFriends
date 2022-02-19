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

    var todayActivitySummary: ActivitySummary? {
        didSet {
            guard let summary = todayActivitySummary else { return }

            var list = listItems.filter { $0 is CompetitionOverview }

            // The activity summary is always first in the list
            list.insert(summary, at: 0)

            listItems = list
        }
    }

    private var currentCompetitions: [CompetitionOverview]? {
        didSet {
            guard let competitions = currentCompetitions else { return }

            var list: [IdentifiableBase]
            if let firstItem = listItems.first, firstItem is ActivitySummary {
                // Remove all existing competitions from the list and re-add the new data
                list = listItems.filter { $0 is ActivitySummary }
                list.insert(contentsOf: competitions, at: 1)
            } else {
                list = []
                list.insert(contentsOf: competitions, at: 0)
            }

            listItems = list
        }
    }

    /// Holds the list of items that the homepage should display
    /// This will start with the current activity summary, if available,
    /// followed by all of the available competition overviews
    @Published var listItems: [IdentifiableBase]

    private var competitionLoadListener: AnyCancellable?

    init(competitionManager: CompetitionManager, healthKitManager: HealthKitManager) {
        self.competitionManager = competitionManager
        self.healthKitManager = healthKitManager

        listItems = []

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
