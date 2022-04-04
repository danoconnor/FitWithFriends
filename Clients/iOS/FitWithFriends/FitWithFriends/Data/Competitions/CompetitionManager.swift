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

    @Published private(set) var competitionOverviews: [UUID: CompetitionOverview]

    init(authenticationManager: AuthenticationManager,
         competitionService: CompetitionService) {
        self.authenticationManager = authenticationManager
        self.competitionService = competitionService

        competitionOverviews = [:]

        loginStateCancellable = authenticationManager.$loginState.sink { [weak self] state in
            switch state {
            case .loggedIn:
                // When the user logs in we want to begin fetching the latest state of their competitions
                guard let self = self else { return }
                Task.detached {
                    await self.refreshCompetitionOverviews()
                }
            default:
                break
            }
        }
    }

    func createCompetition(startDate: Date, endDate: Date, competitionName: String) async -> Error? {


        let error = await competitionService.createCompetition(startDate: startDate,
                                                                endDate: endDate,
                                                                competitionName: competitionName)

        if let error = error {
            Logger.traceError(message: "Failed to create competition", error: error)
        } else {
            Logger.traceInfo(message: "Successfully created competition")
        }

        // Fire-and-forget a task to refresh the competition data
        Task.detached {
            await self.refreshCompetitionOverviews()
        }

        return error
    }

    func refreshCompetitionOverviews() async {
        guard let loggedInUserId = self.authenticationManager.loggedInUserId else {
            Logger.traceWarning(message: "Tried to refresh competition overviews without a logged in user ID")
            return
        }

        Logger.traceInfo(message: "Starting competition overview refresh")

        // Get the competitions that the user is a part of, then fetch the overviews for those competitions
        let usersCompetitionResult = await competitionService.getUsersCompetitions(userId: loggedInUserId)
        guard let competitionIds = usersCompetitionResult.xtSuccess else {
            Logger.traceError(message: "Failed to fetch competitions for user \(loggedInUserId)", error: usersCompetitionResult.xtError)
            return
        }

        let refreshedData = await withTaskGroup(of: (UUID, CompetitionOverview)?.self, returning: [UUID: CompetitionOverview].self) { group in
            for competitionId in competitionIds {
                group.addTask {
                    let overviewResult = await self.competitionService.getCompetitionOverview(competitionId: competitionId)

                    switch overviewResult {
                    case let .success(overview):
                        return (competitionId, overview)
                    case let .failure(error):
                        Logger.traceError(message: "Failed to get competition overview for competition \(competitionId)", error: error)
                        return nil
                    }
                }
            }

            var results = [UUID: CompetitionOverview]()
            for await result in group {
                guard let result = result else { continue }
                results[result.0] = result.1
            }

            return results
        }

        await MainActor.run {
            self.competitionOverviews = refreshedData
        }
    }

    func joinCompetition(competitionId: UUID, competitionToken: String) async -> Error? {
        return await competitionService.joinCompetition(competitionId: competitionId, competitionToken: competitionToken)
    }

    func leaveCompetition(competitionId: UUID) async -> Error? {
        guard let currentUserId = authenticationManager.loggedInUserId else {
            Logger.traceWarning(message: "Tried to leave competition with no logged in user")
            return TokenError.notFound
        }

        return await competitionService.removeUserFromCompetition(userId: currentUserId, competitionId: competitionId)
    }

    func removeUserFromCompetition(competitionId: UUID, targetUser: String) async -> Error? {
        return await competitionService.removeUserFromCompetition(userId: targetUser, competitionId: competitionId)
    }

    func getCompetitionDescription(for competitionId: UUID, competitionToken: String) async -> Result<CompetitionDescription, Error> {
        return await competitionService.getCompetitionDetails(competitionId: competitionId, competitionToken: competitionToken)
    }

    func getCompetitionAdminDetail(for competitionId: UUID) async -> Result<CompetitionAdminDetails, Error> {
        return await competitionService.getCompetitionAdminDetails(competitionId: competitionId)
    }
}

extension CompetitionManager: ActivityUpdateDelegate {
    func activityDataUpdated() {
        // When we have new activity data in the service, re-fetch the competition data
        // so it is up-to-date
        Task.detached {
            await self.refreshCompetitionOverviews()
        }
    }
}
