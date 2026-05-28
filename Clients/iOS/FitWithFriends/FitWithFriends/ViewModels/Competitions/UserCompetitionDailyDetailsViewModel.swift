//
//  UserCompetitionDailyDetailsViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/9/26.
//

import Foundation
import SwiftUI

public class UserCompetitionDailyDetailsViewModel: ObservableObject {
    private let competitionManager: ICompetitionManager
    private let competitionId: UUID
    private let userId: String

    let userName: String

    @Published var dailySummaries: [DailySummary] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var totalPoints: Double = 0
    @Published var scoringUnit: ScoringUnit = .points

    /// Label shown under the big total number. Unit-aware so non-ring competitions make sense.
    var totalLabel: String {
        switch scoringUnit {
        case .points: return "total points"
        case .kcal: return "total calories"
        case .minutes: return "total minutes"
        case .meters: return "total distance"
        case .steps: return "total steps"
        }
    }

    /// Average per-day value in the same unit as the total.
    var dailyAverage: Double {
        guard !dailySummaries.isEmpty else { return 0 }
        return totalPoints / Double(dailySummaries.count)
    }

    var dailyAverageDisplay: String {
        ScoringValueFormatter.format(dailyAverage, unit: scoringUnit)
    }

    /// Number of days where the user closed all three Apple Activity rings.
    /// Precise label so "streak" never gets confused with "days logged".
    var fullRingDayCount: Int {
        dailySummaries.filter { Self.closedAllRings($0) }.count
    }

    /// The day the user earned the most points in this competition.
    var personalBestDate: Date? {
        dailySummaries.max(by: { $0.points < $1.points })?.date
    }

    /// 0..1 intensity per day, sorted chronologically (oldest first). Drives the
    /// calendar heatmap strip. Normalised against the user's own best day so
    /// every comp gets a usable gradient even when scores are small.
    var heatmapIntensities: [(date: Date, intensity: Double)] {
        let sortedAsc = dailySummaries.sorted { $0.date < $1.date }
        let best = sortedAsc.map(\.points).max() ?? 0
        return sortedAsc.map { summary in
            let raw = best > 0 ? summary.points / best : 0
            let floored = max(0.1, raw)  // never fully empty for a logged day
            return (summary.date, min(1.0, floored))
        }
    }

    init(competitionManager: ICompetitionManager,
         competitionId: UUID,
         userId: String,
         userName: String) {
        self.competitionManager = competitionManager
        self.competitionId = competitionId
        self.userId = userId
        self.userName = userName
    }

    @MainActor
    func loadDetails() async {
        isLoading = true
        errorMessage = nil

        do {
            let details = try await competitionManager.getUserCompetitionDetails(
                competitionId: competitionId, userId: userId)

            dailySummaries = details.dailySummaries.sorted { $0.date > $1.date }
            totalPoints = details.dailySummaries.reduce(0) { $0 + $1.points }
            scoringUnit = details.scoringUnit
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            Logger.traceError(message: "Failed to load user competition details", error: error)
            errorMessage = "Failed to load details"
            isLoading = false
        }
    }

    private static func closedAllRings(_ summary: DailySummary) -> Bool {
        guard summary.caloriesGoal > 0 else { return false }
        let move = summary.caloriesBurned >= summary.caloriesGoal
        let exercise = summary.exerciseTimeGoal == 0 || summary.exerciseTime >= summary.exerciseTimeGoal
        let stand = summary.standTimeGoal == 0 || summary.standTime >= summary.standTimeGoal
        return move && exercise && stand
    }
}
