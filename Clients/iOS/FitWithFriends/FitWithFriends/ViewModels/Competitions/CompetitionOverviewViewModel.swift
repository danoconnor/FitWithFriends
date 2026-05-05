//
//  CompetitionDetailViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/4/21.
//

import Combine
import Foundation

public class CompetitionOverviewViewModel: ObservableObject {
    enum CompetitionAction: CustomStringConvertible, Hashable, Comparable {
        case deleteCompetition
        case leave
        case share
        case removeUser(String)

        var description: String {
            switch self {
            case .deleteCompetition:
                return "Delete competition"
            case .leave:
                return "Leave competition"
            case .share:
                return "Share"
            case .removeUser:
                return "Remove user"
            }
        }
    }

    private let authenticationManager: IAuthenticationManager
    private let competitionManager: ICompetitionManager
    private let competitionOverview: CompetitionOverview
    private let serverEnvironmentManager: IServerEnvironmentManager
    private let showAllDetails: Bool

    private var overviewCancellable: AnyCancellable?

    let competitionName: String
    let competitionDatesDescription: String
    let availableActions: [CompetitionAction]

    @Published private(set) var isCompetitionActive: Bool
    @Published private(set) var userPositionDescription: String
    @Published private(set) var results: [UserPosition]

    @Published var shouldShowSheet = false
    var shareUrl: URL?

    @Published var shouldShowAlert = false

    init(authenticationManager: IAuthenticationManager,
         competitionManager: ICompetitionManager,
         competitionOverview: CompetitionOverview,
         serverEnrivonmentManager: IServerEnvironmentManager,
         showAllDetails: Bool) {
        self.authenticationManager = authenticationManager
        self.competitionManager = competitionManager
        self.competitionOverview = competitionOverview
        self.serverEnvironmentManager = serverEnrivonmentManager
        self.showAllDetails = showAllDetails

        competitionName = competitionOverview.competitionName

        if competitionOverview.isUserAdmin {
            availableActions = [.share, .deleteCompetition]
        } else {
            availableActions = [.leave]
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        let startString = dateFormatter.string(from: competitionOverview.startDate)
        let endString = dateFormatter.string(from: competitionOverview.endDate)
        competitionDatesDescription = "\(startString) - \(endString)"

        // Compute initial values for live-updating properties
        let (initialResults, initialPositionDescription, initialIsActive) =
            CompetitionOverviewViewModel.computeDynamicProperties(
                overview: competitionOverview,
                userId: authenticationManager.loggedInUserId,
                showAllDetails: showAllDetails
            )
        isCompetitionActive = initialIsActive
        userPositionDescription = initialPositionDescription
        results = initialResults

        let competitionId = competitionOverview.competitionId
        overviewCancellable = competitionManager.competitionOverviewsPublisher
            .receive(on: DispatchQueue.main)
            .compactMap { $0[competitionId] }
            .sink { [weak self] updated in
                guard let self else { return }
                let (newResults, newPositionDescription, newIsActive) =
                    CompetitionOverviewViewModel.computeDynamicProperties(
                        overview: updated,
                        userId: self.authenticationManager.loggedInUserId,
                        showAllDetails: self.showAllDetails
                    )
                self.isCompetitionActive = newIsActive
                self.userPositionDescription = newPositionDescription
                self.results = newResults
            }
    }

    func performAction(_ action: CompetitionAction) async {
        switch action {
        case .deleteCompetition:
            await MainActor.run {
                self.shouldShowAlert = true
            }
        case .leave:
            await leaveCompetition()
        case .share:
            await shareCompetition()
        case let .removeUser(userId):
            await removeUser(userId: userId)
        }
    }

    func getUserContextMenuActions(for userId: String) -> [CompetitionAction] {
        var actions = [CompetitionAction]()
        if competitionOverview.isUserAdmin && userId != authenticationManager.loggedInUserId {
            actions.append(.removeUser(userId))
        }
        return actions
    }

    func deleteCompetitionConfirmed() async {
        do {
            try await competitionManager.deleteCompetition(competitionId: competitionOverview.competitionId)
        } catch {
            Logger.traceError(message: "Failed to delete competition \(competitionOverview.competitionId)", error: error)
        }

        await competitionManager.refreshCompetitionOverviews()
    }

    private func leaveCompetition() async {
        do {
            try await competitionManager.leaveCompetition(competitionId: competitionOverview.competitionId)
        } catch {
            Logger.traceError(message: "Failed to leave competition \(competitionOverview.competitionId)", error: error)
        }

        await competitionManager.refreshCompetitionOverviews()
    }

    private func removeUser(userId: String) async {
        do {
            try await competitionManager.removeUserFromCompetition(competitionId: competitionOverview.competitionId, targetUser: userId)
        } catch {
            Logger.traceError(message: "Failed to remove user \(userId) from competition \(competitionOverview.competitionId)", error: error)
        }

        await competitionManager.refreshCompetitionOverviews()
    }

    private func shareCompetition() async {
        do {
            let adminDetail = try await competitionManager.getCompetitionAdminDetail(for: competitionOverview.competitionId)

            shareUrl = JoinCompetitionProtocolData.createWebsiteUrl(serverBaseUrl: serverEnvironmentManager.baseUrl,
                                                                    competitionId: adminDetail.competitionId,
                                                                    competitionToken: adminDetail.competitionAccessToken)
            await MainActor.run {
                self.shouldShowSheet = true
            }
        } catch {
            Logger.traceError(message: "Failed to get admin details for \(competitionOverview.competitionId)", error: error)
        }
    }

    private static func computeDynamicProperties(
        overview: CompetitionOverview,
        userId: String?,
        showAllDetails: Bool
    ) -> (results: [UserPosition], userPositionDescription: String, isCompetitionActive: Bool) {
        let allResults = overview.currentResults.sorted()
        let userPositionZeroIndex = allResults.firstIndex { $0.userId == userId } ?? -1
        let userPosition = userPositionZeroIndex + 1

        let userPositionSuffix: String
        if userPosition > 3 {
            userPositionSuffix = "th"
        } else if userPosition == 3 {
            userPositionSuffix = "rd"
        } else if userPosition == 2 {
            userPositionSuffix = "nd"
        } else {
            userPositionSuffix = "st"
        }

        let numResultsToInclude = showAllDetails ? allResults.count : min(allResults.count, 3)
        var results: [UserPosition] = []
        for i in 0 ..< numResultsToInclude {
            results.append(UserPosition(userCompetitionPoints: allResults[i], position: UInt(i + 1)))
        }
        if userPosition > numResultsToInclude {
            results.append(UserPosition(userCompetitionPoints: allResults[userPositionZeroIndex], position: UInt(userPosition)))
        }

        let userPositionDescription: String
        if overview.hasCompetitionStarted && userPosition > 0 {
            if overview.isCompetitionProcessingResults {
                userPositionDescription = "Processing final results..."
            } else {
                let prefix = Date() > overview.endDate ? "You finished in" : "You're in"
                userPositionDescription = "\(prefix) \(userPosition)\(userPositionSuffix)"
            }
        } else {
            userPositionDescription = "Not started"
        }

        return (results, userPositionDescription, overview.isCompetitionActive)
    }
}
