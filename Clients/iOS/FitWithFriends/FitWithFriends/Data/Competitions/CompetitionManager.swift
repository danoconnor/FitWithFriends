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
    private let competitionService: ICompetitionService

    private var loginStateCancellable: AnyCancellable?

    @Published private(set) var competitionOverviews: [UUID: CompetitionOverview]

    init(authenticationManager: AuthenticationManager,
         competitionService: ICompetitionService) {
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

    func createCompetition(startDate: Date, endDate: Date, competitionName: String) async throws {


        do {
            try await competitionService.createCompetition(startDate: startDate,
                                                           endDate: endDate,
                                                           competitionName: competitionName)

            Logger.traceInfo(message: "Successfully created competition")

            // Fire-and-forget a task to refresh the competition data
            Task.detached {
                await self.refreshCompetitionOverviews()
            }

        } catch {
            Logger.traceError(message: "Failed to create competition", error: error)
            throw error
        }
    }

    func refreshCompetitionOverviews() async {
        guard let loggedInUserId = self.authenticationManager.loggedInUserId else {
            Logger.traceWarning(message: "Tried to refresh competition overviews without a logged in user ID")
            return
        }

        Logger.traceInfo(message: "Starting competition overview refresh")

        // Get the competitions that the user is a part of, then fetch the overviews for those competitions
        let competitionIds: [UUID]
        do {
            competitionIds = try await competitionService.getUsersCompetitions(userId: loggedInUserId)
        } catch {
            Logger.traceError(message: "Failed to fetch competitions for user \(loggedInUserId)", error: error)
            return
        }

        let refreshedData = await withTaskGroup(of: (UUID, CompetitionOverview)?.self, returning: [UUID: CompetitionOverview].self) { group in
            for competitionId in competitionIds {
                group.addTask {
                    do {
                        let competitionOverview = try await self.competitionService.getCompetitionOverview(competitionId: competitionId)
                        return (competitionId, competitionOverview)
                    } catch {
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

    func joinCompetition(competitionId: UUID, competitionToken: String) async throws {
        try await competitionService.joinCompetition(competitionId: competitionId, competitionToken: competitionToken)
    }

    func leaveCompetition(competitionId: UUID) async throws {
        guard let currentUserId = authenticationManager.loggedInUserId else {
            Logger.traceWarning(message: "Tried to leave competition with no logged in user")
            throw TokenError.notFound
        }

        try await competitionService.removeUserFromCompetition(userId: currentUserId, competitionId: competitionId)
    }

    func removeUserFromCompetition(competitionId: UUID, targetUser: String) async throws {
        try await competitionService.removeUserFromCompetition(userId: targetUser, competitionId: competitionId)
    }

    func getCompetitionDescription(for competitionId: UUID, competitionToken: String) async throws -> CompetitionDescription {
        return try await competitionService.getCompetitionDescription(competitionId: competitionId, competitionToken: competitionToken)
    }

    func getCompetitionAdminDetail(for competitionId: UUID) async throws -> CompetitionAdminDetails {
        return try await competitionService.getCompetitionAdminDetails(competitionId: competitionId)
    }

    func deleteCompetition(competitionId: UUID) async throws {
        return try await competitionService.deleteCompetition(competitionId: competitionId)
    }
}

extension CompetitionManager: ActivityUpdateDelegate {
    public func activityDataUpdated() {
        // When we have new activity data in the service, re-fetch the competition data
        // so it is up-to-date
        Task.detached {
            await self.refreshCompetitionOverviews()
        }
    }
}
