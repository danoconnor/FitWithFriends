//
//  CompetitionDetailViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/4/21.
//

import Combine
import Foundation

class CompetitionOverviewViewModel: ObservableObject {
    enum CompetitionAction: CustomStringConvertible, Hashable {
        case leave
        case share
        case removeUser(UInt)

        var description: String {
            switch self {
            case .leave:
                return "Leave competition"
            case .share:
                return "Share"
            case .removeUser:
                return "Remove user"
            }
        }
    }

    private let authenticationManager: AuthenticationManager
    private let competitionManager: CompetitionManager
    private let competitionOverview: CompetitionOverview

    /// When false, it will only show the top three users in the competition
    private let showAllDetails: Bool

    let competitionName: String
    let userPositionDescription: String
    let competitionDatesDescription: String
    let availableActions: [CompetitionAction]
    private(set) var results: [UserPosition]

    @Published var shouldShowSheet = false
    var shareUrl: URL?

    init(authenticationManager: AuthenticationManager,
         competitionManager: CompetitionManager,
         competitionOverview: CompetitionOverview,
         showAllDetails: Bool) {
        self.authenticationManager = authenticationManager
        self.competitionManager = competitionManager
        self.competitionOverview = competitionOverview
        self.showAllDetails = showAllDetails

        competitionName = competitionOverview.competitionName

        if competitionOverview.isUserAdmin {
            // If the user is the competition admin,
            // then they can generate a link to share the competition with others
            // and allow them to join
            availableActions = [.share]
        } else {
            // Only allow non-admins to leave the competition
            // TODO: need some way for the admin to leave/disband the competition
            availableActions = [.leave]
        }

        let allResults = competitionOverview.currentResults.sorted { $0.totalPoints > $1.totalPoints }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        let startString = dateFormatter.string(from: competitionOverview.competitionStart)
        let endString = dateFormatter.string(from: competitionOverview.competitionEnd)
        competitionDatesDescription = "\(startString) - \(endString)"

        // Find the user's current position in the results
        let userPositionZeroIndex = allResults.firstIndex { $0.userId == authenticationManager.loggedInUserId } ?? -1
        let userPosition = userPositionZeroIndex + 1
        
        let userPositionString: String
        if userPosition > 3 {
            userPositionString = "th"
        } else if userPosition == 3 {
            userPositionString = "rd"
        } else if userPosition == 2 {
            userPositionString = "nd"
        } else {
            userPositionString = "st"
        }

        // If we aren't showing all details, then only show the top three users
        let numResultsToInclude = showAllDetails ? allResults.count : min(allResults.count, 3)

        // allResults has been sorted above already
        results = []
        for i in 0 ..< numResultsToInclude {
            results.append(UserPosition(userCompetitionPoints: allResults[i], position: UInt(i + 1)))
        }

        // Always include the current user, even if they're not in the top 3
        if userPosition > numResultsToInclude {
            results.append(UserPosition(userCompetitionPoints: allResults[userPositionZeroIndex], position: UInt(userPosition)))
        }

        let userPositionPrefix = Date() > competitionOverview.competitionEnd ? "You finished in" : "You're in"

        userPositionDescription = "\(userPositionPrefix) \(userPosition)\(userPositionString)"
    }

    func performAction(_ action: CompetitionAction) async {
        switch action {
        case .leave:
            await leaveCompetition()
        case .share:
            await shareCompetition()
        case let .removeUser(userId):
            await removeUser(userId: userId)
        }
    }

    func getUserContextMenuActions(for userId: UInt) -> [CompetitionAction] {
        var actions = [CompetitionAction]()

        // Allow the admin user to remove other users from the competition via the context menu
        if competitionOverview.isUserAdmin && userId != authenticationManager.loggedInUserId {
            actions.append(.removeUser(userId))
        }

        return actions
    }

    private func leaveCompetition() async {
        let error = await competitionManager.leaveCompetition(competitionId: competitionOverview.competitionId)
        if error != nil {
            Logger.traceError(message: "Failed to leave competition \(competitionOverview.competitionId)", error: error)
        }

        await competitionManager.refreshCompetitionOverviews()
    }

    private func removeUser(userId: UInt) async {
        let error = await competitionManager.removeUserFromCompetition(competitionId: competitionOverview.competitionId, targetUser: userId)
        if error != nil {
            Logger.traceError(message: "Failed to remove user \(userId) from competition \(competitionOverview.competitionId)", error: error)
        }

        await competitionManager.refreshCompetitionOverviews()
    }

    private func shareCompetition() async {
        let adminDetailResult = await competitionManager.getCompetitionAdminDetail(for: competitionOverview.competitionId)
        guard let adminDetail = adminDetailResult.xtSuccess else {
            Logger.traceError(message: "Failed to get admin details for \(competitionOverview.competitionId)", error: adminDetailResult.xtError)
            return
        }

        shareUrl = JoinCompetitionProtocolData.createWebsiteUrl(competitionId: adminDetail.competitionId, competitionToken: adminDetail.competitionAccessToken)
        await MainActor.run {
            self.shouldShowSheet = true
        }
    }
}
