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

    @Published private(set) var competitionOverviews: [UInt: CompetitionOverview]

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

    func refreshCompetitionOverviews(completion: (() -> Void)? = nil) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            guard let loggedInUserId = self.authenticationManager.loggedInUserId else {
                Logger.traceWarning(message: "Tried to refresh competition overviews without a logged in user ID")
                return
            }

            Logger.traceInfo(message: "Starting competition overview refresh")

            // Get the competitions that the user is a part of, then fetch the overviews for those competitions
            self.competitionService.getUsersCompetitions(userId: loggedInUserId) { usersCompetitionResult in
                guard let competitionIds = usersCompetitionResult.xtSuccess else {
                    Logger.traceError(message: "Failed to fetch competitions for user \(loggedInUserId)", error: usersCompetitionResult.xtError)
                    return
                }

                let dispatchGroup = DispatchGroup()
                let updateQueue = DispatchQueue(label: "RefreshCompetitionQueue")
                var refreshedData: [UInt: CompetitionOverview] = [:]

                for competitionId in competitionIds {
                    dispatchGroup.enter()
                    self.competitionService.getCompetitionOverview(competitionId: competitionId) { competitionOverviewResult in
                        switch competitionOverviewResult {
                        case let .success(overview):
                            updateQueue.sync {
                                refreshedData[overview.competitionId] = overview
                            }
                        case let .failure(error):
                            Logger.traceError(message: "Failed to get overview for competition \(competitionId)", error: error)
                        }

                        dispatchGroup.leave()
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    self.competitionOverviews = refreshedData
                }
            }
        }
    }
}

extension CompetitionManager: ActivityUpdateDelegate {
    func activityDataUpdated() {
        // When we have new activity data in the service, re-fetch the competition data
        // so it is up-to-date
        refreshCompetitionOverviews()
    }
}
