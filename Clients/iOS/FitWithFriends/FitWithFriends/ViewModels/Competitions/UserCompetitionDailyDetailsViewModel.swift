//
//  UserCompetitionDailyDetailsViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/9/26.
//

import Foundation

public class UserCompetitionDailyDetailsViewModel: ObservableObject {
    private let competitionManager: ICompetitionManager
    private let competitionId: UUID
    private let userId: String

    let userName: String

    @Published var dailySummaries: [DailySummary] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var totalPoints: Double = 0

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
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            Logger.traceError(message: "Failed to load user competition details", error: error)
            errorMessage = "Failed to load details"
            isLoading = false
        }
    }
}
