//
//  CompetitionEndAlertViewModel.swift
//  FitWithFriends
//

import Combine
import Foundation
import SwiftUI

@MainActor
class CompetitionEndAlertViewModel: ObservableObject {
    /// Variants drive the end-of-competition celebration screen — the lower the
    /// finish, the more the design shrinks the rank chrome and grows the
    /// personal stats. Last place should be all personal.
    enum EndVariant {
        case won
        case silver
        case bronze
        case midPack
        case last
    }

    @Published var currentEndCompetition: CompetitionOverview?
    @Published var shouldShowConfetti: Bool = false
    @Published var dailySummaries: [DailySummary] = []
    @Published var isLoadingSummaries: Bool = false

    private var pendingCompetitions: [CompetitionOverview] = []
    private var cancellable: AnyCancellable?
    private let authenticationManager: IAuthenticationManager
    private let competitionManager: ICompetitionManager?
    private let userDefaults: UserDefaults

    init(competitionManager: ICompetitionManager,
         authenticationManager: IAuthenticationManager,
         userDefaults: UserDefaults = .standard) {
        self.authenticationManager = authenticationManager
        self.competitionManager = competitionManager
        self.userDefaults = userDefaults

        cancellable = competitionManager.competitionOverviewsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] overviews in
                self?.processNewOverviews(overviews)
            }
    }

    private func processNewOverviews(_ overviews: [UUID: CompetitionOverview]) {
        guard currentEndCompetition == nil else { return }

        let unseen = overviews.values
            .filter { $0.competitionState == .archived }
            .filter { !userDefaults.bool(forKey: seenKey(for: $0.competitionId)) }
            .sorted { $0.endDate > $1.endDate }

        pendingCompetitions.append(contentsOf: unseen)
        showNextIfNeeded()
    }

    func dismissCurrent() {
        if let current = currentEndCompetition {
            userDefaults.set(true, forKey: seenKey(for: current.competitionId))
        }
        shouldShowConfetti = false
        currentEndCompetition = nil
        dailySummaries = []
        showNextIfNeeded()
    }

    private func showNextIfNeeded() {
        guard currentEndCompetition == nil, let next = pendingCompetitions.first else { return }
        pendingCompetitions.removeFirst()

        // The user is about to see the final results, so tell the server to suppress
        // the fallback push for this competition.
        markNotificationsSeen(for: next.competitionId)

        let position = userPosition(in: next) ?? Int.max
        // The podium sheet (Direction B) celebrates a win only — confetti fires
        // exclusively when the user finishes 1st. Podium finishes 2nd/3rd are
        // still honored visually by the podium, but without confetti.
        let willShowConfetti = position == 1
        if willShowConfetti {
            // Start confetti first so particles are already in motion when the
            // sheet appears, keeping them visible to the user.
            shouldShowConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.currentEndCompetition = next
                self?.loadSummaries()
            }
        } else {
            currentEndCompetition = next
            loadSummaries()
        }
    }

    private func loadSummaries() {
        guard let competition = currentEndCompetition,
              let userId = authenticationManager.loggedInUserId,
              let manager = competitionManager else { return }

        isLoadingSummaries = true
        Task { @MainActor in
            do {
                let details = try await manager.getUserCompetitionDetails(competitionId: competition.competitionId, userId: userId)
                self.dailySummaries = details.dailySummaries.sorted { $0.date > $1.date }
            } catch {
                Logger.traceError(message: "Failed to load daily summaries for ended competition", error: error)
            }
            self.isLoadingSummaries = false
        }
    }

    // MARK: - Computed properties for the end view

    var endVariant: EndVariant {
        guard let competition = currentEndCompetition,
              let position = userPosition(in: competition) else {
            return .midPack
        }
        let total = competition.currentResults.count
        switch position {
        case 1: return .won
        case 2: return .silver
        case 3: return .bronze
        default:
            return position == total ? .last : .midPack
        }
    }

    /// "1st", "2nd", etc. — nil when the user wasn't in the competition.
    var userPositionOrdinal: String? {
        guard let competition = currentEndCompetition,
              let position = userPosition(in: competition) else { return nil }
        return CompetitionOverviewViewModel.ordinal(position)
    }

    // MARK: - Podium sheet (Direction B) presentation model

    /// Three-way outcome that drives the podium sheet's gradient, confetti, and copy.
    /// `won` (1st) is the loud, celebratory state; `last` (finished dead last) is the
    /// gracious state; everyone in between is `mid`.
    enum EndOutcome {
        case won
        case mid
        case last
    }

    var endOutcome: EndOutcome {
        guard let competition = currentEndCompetition,
              let position = userPosition(in: competition) else {
            return .mid
        }
        if position == 1 { return .won }
        if position == competition.currentResults.count { return .last }
        return .mid
    }

    /// The current user's 1-based final placement, or `nil` when they weren't in the results.
    var userPlacement: Int? {
        guard let competition = currentEndCompetition else { return nil }
        return userPosition(in: competition)
    }

    /// Whether the user landed on the podium (top 3) — drives the highlighted pedestal.
    var isUserOnPodium: Bool {
        guard let placement = userPlacement else { return false }
        return placement <= 3
    }

    /// Total number of competitors.
    var memberCount: Int {
        currentEndCompetition?.currentResults.count ?? 0
    }

    /// Italic serif accent rendered on the second line of the headline.
    var headlineAccent: String {
        switch endOutcome {
        case .won:  return "You won."
        case .mid:  return "Strong showing."
        case .last: return "Every day counts."
        }
    }

    /// One-line subline under the "You finished" title.
    var outcomeSubline: String {
        switch endOutcome {
        case .won:
            return "First place is yours. Nobody closed more."
        case .mid:
            return "Right in the hunt — a couple of big days from the podium."
        case .last:
            return "You logged \(competitionDayCount) days and never quit. That's the whole point."
        }
    }

    /// Whole calendar days the competition spanned (inclusive), floored at 1. Derived from the
    /// date range so it's available immediately, without waiting on the daily-summary load.
    private var competitionDayCount: Int {
        guard let competition = currentEndCompetition else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: competition.startDate, to: competition.endDate).day ?? 0
        return max(1, days)
    }

    /// One podium slot for the top-3 visualization.
    struct PodiumEntry: Identifiable {
        let id = UUID()
        let position: Int
        let firstName: String
        let displayName: String
        let points: Double?
        let isCurrentUser: Bool
    }

    /// The competition's actual top three, ordered 1 → 3. Always the real top 3 — when the user
    /// finished mid-pack or last they won't appear here, only in the "You finished" row below.
    var podiumEntries: [PodiumEntry] {
        guard let competition = currentEndCompetition else { return [] }
        let userId = authenticationManager.loggedInUserId
        return competition.currentResults.sorted().prefix(3).enumerated().map { index, points in
            PodiumEntry(position: index + 1,
                        firstName: points.firstName,
                        displayName: points.displayName,
                        points: points.totalPoints,
                        isCurrentUser: points.userId == userId)
        }
    }

    /// The user's total score, formatted compactly without a unit suffix (the row shows a
    /// separate "PTS"/"STEPS"/… tag beside it).
    var userScoreValue: String {
        guard let competition = currentEndCompetition,
              let row = competition.currentResults.first(where: { $0.userId == authenticationManager.loggedInUserId }),
              let total = row.totalPoints else { return "—" }
        return ScoringValueFormatter.formatCompact(total, unit: competition.scoringUnit)
    }

    /// App Store listing for Fit with Friends — the payload attached to a shared result so
    /// recipients can download the app.
    static let appStoreURL = "https://apps.apple.com/app/id6451087375"

    /// Hype-friend result sentence that accompanies the shared result card. Trophy emoji is
    /// earned only on a win, matching the rest of the design's voice.
    var shareText: String {
        guard let competition = currentEndCompetition, let ordinal = userPositionOrdinal else {
            return "Check out my results on Fit with Friends!"
        }
        switch endOutcome {
        case .won:
            return "🏆 I finished \(ordinal) of \(memberCount) in \(competition.competitionName) on Fit with Friends!"
        case .mid:
            return "I finished \(ordinal) of \(memberCount) in \(competition.competitionName) on Fit with Friends. 💪"
        case .last:
            return "I logged \(competitionDayCount) days in \(competition.competitionName) on Fit with Friends and never quit. 💪"
        }
    }

    /// Short, uppercase unit tag shown beside the user's score ("PTS", "STEPS", "KCAL", …).
    var unitTagText: String {
        guard let competition = currentEndCompetition else { return "PTS" }
        switch competition.scoringUnit {
        case .points:  return "PTS"
        case .steps:   return "STEPS"
        case .kcal:    return "KCAL"
        case .minutes: return "MIN"
        case .meters:  return Locale.current.measurementSystem == .metric ? "KM" : "MI"
        }
    }

    /// Number of days where the user closed all three Apple Activity rings.
    var daysClosedAllRings: Int {
        dailySummaries.filter { Self.closedAllRings($0) }.count
    }

    /// Longest consecutive run of days where the user closed their Move ring.
    /// Strict "Move ring streak" definition — never use the looser "days logged".
    var moveRingStreak: Int {
        let chronological = dailySummaries.sorted { $0.date < $1.date }
        var best = 0
        var current = 0
        for summary in chronological {
            if summary.caloriesGoal > 0 && summary.caloriesBurned >= summary.caloriesGoal {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    /// The day where the user earned the highest score.
    var bestDay: (date: Date, points: Double)? {
        guard let top = dailySummaries.max(by: { $0.points < $1.points }) else { return nil }
        return (top.date, top.points)
    }

    /// Total points across all days, in the competition's scoring unit.
    var totalPoints: Double {
        dailySummaries.reduce(0) { $0 + $1.points }
    }

    /// Display string for total in the comp's native unit, falling back to the
    /// user's row on the competition overview when daily summaries haven't
    /// finished loading yet.
    var totalDisplay: String {
        if let competition = currentEndCompetition {
            let unit = competition.scoringUnit
            if totalPoints > 0 {
                return ScoringValueFormatter.format(totalPoints, unit: unit)
            }
            if let myRow = competition.currentResults.first(where: { $0.userId == authenticationManager.loggedInUserId }),
               let total = myRow.totalPoints {
                return ScoringValueFormatter.format(total, unit: unit)
            }
        }
        return "—"
    }

    /// First-place finisher in the current competition (used by the silver variant).
    var winner: UserCompetitionPoints? {
        guard let competition = currentEndCompetition else { return nil }
        return competition.currentResults.sorted().first
    }

    /// "60 points behind Alice"
    var gapToFirst: String? {
        guard let competition = currentEndCompetition,
              let winner = winner,
              let userRow = competition.currentResults.first(where: { $0.userId == authenticationManager.loggedInUserId }),
              let winnerTotal = winner.totalPoints,
              let userTotal = userRow.totalPoints,
              winnerTotal > userTotal else { return nil }
        let formatted = ScoringValueFormatter.format(winnerTotal - userTotal, unit: competition.scoringUnit)
        return formatted
    }

    private func userPosition(in competition: CompetitionOverview) -> Int? {
        guard let userId = authenticationManager.loggedInUserId else { return nil }
        let sorted = competition.currentResults.sorted()
        guard let idx = sorted.firstIndex(where: { $0.userId == userId }) else { return nil }
        return idx + 1
    }

    private func markNotificationsSeen(for competitionId: UUID) {
        guard let manager = competitionManager else { return }
        Task.detached {
            do {
                try await manager.markCompetitionNotificationsSeen(competitionId: competitionId)
            } catch {
                Logger.traceWarning(message: "Failed to mark competition notifications seen: \(error)")
            }
        }
    }

    private func seenKey(for competitionId: UUID) -> String {
        "hasSeenCompetitionEndAlert_\(competitionId.uuidString)"
    }

    private static func closedAllRings(_ summary: DailySummary) -> Bool {
        guard summary.caloriesGoal > 0 else { return false }
        let move = summary.caloriesBurned >= summary.caloriesGoal
        let exercise = summary.exerciseTimeGoal == 0 || summary.exerciseTime >= summary.exerciseTimeGoal
        let stand = summary.standTimeGoal == 0 || summary.standTime >= summary.standTimeGoal
        return move && exercise && stand
    }

    // MARK: - Back-compat (so existing call sites that read alertTitle/alertMessage compile)

    var currentAlertCompetition: CompetitionOverview? { currentEndCompetition }
    var alertTitle: String {
        guard let competition = currentEndCompetition else { return "" }
        return "\(competition.competitionName) has ended!"
    }
    var alertMessage: String {
        guard let ord = userPositionOrdinal else { return "The competition has ended." }
        return "You finished in \(ord) place."
    }
    func alertDismissed() { dismissCurrent() }
}
