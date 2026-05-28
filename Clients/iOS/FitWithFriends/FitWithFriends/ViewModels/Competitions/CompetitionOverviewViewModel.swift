//
//  CompetitionOverviewViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/4/21.
//

import Combine
import Foundation
import SwiftUI

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

    /// Today's contribution from the current user in this competition, expressed in
    /// the competition's own scoring unit. Each comp card on the home screen carries
    /// its own delta in its own unit — never compare points across rule families.
    struct TodayDelta {
        let value: String
        let unit: String        // "pts today", "steps today", "min today"
        let color: Color
    }

    /// One-line "Alice leads by 390 pts" style status that anchors the bottom of
    /// the home competition card. Nil before the comp has started or when the
    /// current user is in the lead.
    struct LeaderStatus {
        let name: String
        let relation: String    // "leads by 390 pts" / "ahead by 12,310 steps"
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

    /// Chip label + accent color for the competition's scoring rule (e.g.
    /// "Activity rings" / "Steps" / "Workouts"). The accent matches the
    /// unit color so the card has a consistent visual language.
    let scoringRuleChipLabel: String
    let scoringRuleChipIcon: String
    let scoringRuleChipColor: Color

    @Published private(set) var isCompetitionActive: Bool
    @Published private(set) var userPositionDescription: String
    @Published private(set) var results: [UserPosition]

    @Published private(set) var todayDelta: TodayDelta?
    @Published private(set) var leaderStatus: LeaderStatus?
    @Published private(set) var medalColor: Color?
    @Published private(set) var userRank: Int?
    @Published private(set) var userRankOrdinal: String?
    @Published private(set) var totalParticipants: Int = 0
    @Published private(set) var daysLeft: Int = 0

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

        let chip = Self.scoringChip(for: competitionOverview.scoringRules)
        scoringRuleChipLabel = chip.label
        scoringRuleChipIcon = chip.icon
        scoringRuleChipColor = chip.color

        // Compute initial values for live-updating properties
        let snapshot = CompetitionOverviewViewModel.computeDynamicProperties(
            overview: competitionOverview,
            userId: authenticationManager.loggedInUserId,
            showAllDetails: showAllDetails
        )
        isCompetitionActive = snapshot.isCompetitionActive
        userPositionDescription = snapshot.userPositionDescription
        results = snapshot.results
        todayDelta = snapshot.todayDelta
        leaderStatus = snapshot.leaderStatus
        medalColor = snapshot.medalColor
        userRank = snapshot.userRank
        userRankOrdinal = snapshot.userRankOrdinal
        totalParticipants = snapshot.totalParticipants
        daysLeft = snapshot.daysLeft

        let competitionId = competitionOverview.competitionId
        overviewCancellable = competitionManager.competitionOverviewsPublisher
            .receive(on: DispatchQueue.main)
            .compactMap { $0[competitionId] }
            .sink { [weak self] updated in
                guard let self else { return }
                let s = CompetitionOverviewViewModel.computeDynamicProperties(
                    overview: updated,
                    userId: self.authenticationManager.loggedInUserId,
                    showAllDetails: self.showAllDetails
                )
                self.isCompetitionActive = s.isCompetitionActive
                self.userPositionDescription = s.userPositionDescription
                self.results = s.results
                self.todayDelta = s.todayDelta
                self.leaderStatus = s.leaderStatus
                self.medalColor = s.medalColor
                self.userRank = s.userRank
                self.userRankOrdinal = s.userRankOrdinal
                self.totalParticipants = s.totalParticipants
                self.daysLeft = s.daysLeft
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

    // MARK: - Pure derivations

    private struct Snapshot {
        let results: [UserPosition]
        let userPositionDescription: String
        let isCompetitionActive: Bool
        let todayDelta: TodayDelta?
        let leaderStatus: LeaderStatus?
        let medalColor: Color?
        let userRank: Int?
        let userRankOrdinal: String?
        let totalParticipants: Int
        let daysLeft: Int
    }

    struct ScoringChip {
        let label: String
        let icon: String
        let color: Color
    }

    static func scoringChip(for rules: ScoringRules) -> ScoringChip {
        switch rules {
        case .rings:
            return ScoringChip(label: "Activity rings", icon: "circle.hexagongrid.fill", color: Color("Brand"))
        case .workouts:
            return ScoringChip(label: "Workouts", icon: "figure.run", color: Color("Move"))
        case let .daily(metric):
            switch metric {
            case .steps: return ScoringChip(label: "Daily steps", icon: "shoeprints.fill", color: Color("Exercise"))
            case .walkingRunningDistance: return ScoringChip(label: "Daily distance", icon: "figure.walk", color: Color("Exercise"))
            }
        }
    }

    static func ordinal(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    /// "leads by 390 pts" / "ahead by 12,310 steps" / "ahead by 22 min"
    static func relationDescription(diff: Double, unit: ScoringUnit) -> String {
        let absDiff = abs(diff)
        let formatted = ScoringValueFormatter.format(absDiff, unit: unit)
        return "leads by \(formatted)"
    }

    static func unitSuffix(for unit: ScoringUnit) -> String {
        switch unit {
        case .points: return "pts today"
        case .steps: return "steps today"
        case .kcal: return "kcal today"
        case .minutes: return "min today"
        case .meters: return "today"
        }
    }

    /// Color used for the per-comp today delta on the home card.
    static func unitColor(for rules: ScoringRules) -> Color {
        switch rules {
        case .rings: return Color("Brand")
        case .daily: return Color("Exercise")
        case .workouts: return Color("Move")
        }
    }

    private static func computeDynamicProperties(
        overview: CompetitionOverview,
        userId: String?,
        showAllDetails: Bool
    ) -> Snapshot {
        let allResults = overview.currentResults.sorted()
        let totalParticipants = allResults.count
        let userPositionZeroIndex = allResults.firstIndex { $0.userId == userId } ?? -1
        let userPosition = userPositionZeroIndex + 1

        let userRank: Int? = userPosition > 0 ? userPosition : nil
        let userRankOrdinal: String? = userRank.map { ordinal($0) }

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

        let medalColor: Color? = {
            switch userPosition {
            case 1: return Color("Gold")
            case 2: return Color("Silver")
            case 3: return Color("Bronze")
            default: return nil
            }
        }()

        // Today's delta in the comp's own unit. Don't synthesize a value when the
        // comp hasn't started — the empty state will show "Not started" instead.
        var todayDelta: TodayDelta? = nil
        if overview.hasCompetitionStarted, userPosition > 0,
           let userResult = allResults.first(where: { $0.userId == userId }),
           let today = userResult.pointsToday {
            let value = ScoringValueFormatter.formatCompact(today, unit: overview.scoringUnit)
            todayDelta = TodayDelta(
                value: "+\(value)",
                unit: unitSuffix(for: overview.scoringUnit),
                color: unitColor(for: overview.scoringRules)
            )
        }

        // Leader status — only relevant when the user is not in 1st place.
        var leaderStatus: LeaderStatus? = nil
        if let leader = allResults.first, leader.userId != userId,
           let userResult = allResults.first(where: { $0.userId == userId }),
           let leaderPoints = leader.totalPoints,
           let userPoints = userResult.totalPoints {
            let diff = leaderPoints - userPoints
            leaderStatus = LeaderStatus(
                name: leader.firstName,
                relation: relationDescription(diff: diff, unit: overview.scoringUnit)
            )
        }

        // Days left — clamp at 0 once the comp is over.
        let secondsLeft = overview.endDate.timeIntervalSince(Date())
        let daysLeft = max(0, Int(ceil(secondsLeft / 86_400)))

        return Snapshot(
            results: results,
            userPositionDescription: userPositionDescription,
            isCompetitionActive: overview.isCompetitionActive,
            todayDelta: todayDelta,
            leaderStatus: leaderStatus,
            medalColor: medalColor,
            userRank: userRank,
            userRankOrdinal: userRankOrdinal,
            totalParticipants: totalParticipants,
            daysLeft: daysLeft
        )
    }
}
