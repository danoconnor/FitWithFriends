//
//  CompetitionManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Combine
import Foundation

public class CompetitionManager: ObservableObject {
    private let authenticationManager: AuthenticationManager
    private let competitionService: CompetitionService

    private var loginStateCancellable: AnyCancellable?

    @Published var competitionOverviews: [UInt: CompetitionOverview]

    init(authenticationManager: AuthenticationManager,
         competitionService: CompetitionService) {
        self.authenticationManager = authenticationManager
        self.competitionService = competitionService

        competitionOverviews = [:]

        loginStateCancellable = authenticationManager.$loginState.sink { [weak self] state in
            if state == .loggedIn {
                // When the user logs in we want to begin fetching the latest state of their competitions
                self?.refreshCompetitionOverviews()
            }
        }
    }

    func createCompetition(startDate: Date, endDate: Date, competitionName: String, completion: @escaping (Error?) -> Void) {
        competitionService.createCompetition(startDate: startDate,
                                             endDate: endDate,
                                             competitionName: competitionName) { [weak self] result in
            if let error = result.xtError {
                Logger.traceError(message: "Failed to create competition", error: error)
            } else {
                Logger.traceInfo(message: "Successfully created competition")
            }

            self?.refreshCompetitionOverviews()
            completion(result.xtError)
        }
    }

    private func refreshCompetitionOverviews() {
        guard let loggedInUserId = authenticationManager.loggedInUserId else {
            Logger.traceWarning(message: "Tried to refresh competition overviews without a logged in user ID")
            return
        }

        // Get the competitions that the user is a part of, then fetch the overviews for those competitions
        competitionService.getUsersCompetitions(userId: loggedInUserId) { [weak self] usersCompetitionResult in
            guard let competitionIds = usersCompetitionResult.xtSuccess else {
                Logger.traceError(message: "Failed to fetch competitions for user \(loggedInUserId)", error: usersCompetitionResult.xtError)
                return
            }

            guard let self = self else { return }

            for competitionId in competitionIds {
                self.competitionService.getCompetitionOverview(competitionId: competitionId) { competitionOverviewResult in
                    switch competitionOverviewResult {
                    case let .success(overview):
                        DispatchQueue.main.async {
                            self.competitionOverviews[competitionId] = overview
                        }
                    case let .failure(error):
                        Logger.traceError(message: "Failed to get overview for competition \(competitionId)", error: error)
                    }
                }
            }
        }
    }
}
