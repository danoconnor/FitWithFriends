//
//  WatchCompetitionDetailViewModel.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import Foundation

/// Presentation logic for a single competition's leaderboard on the Watch.
/// No SwiftUI in here — pure value transformation so tests can exercise it directly.
class WatchCompetitionDetailViewModel {
    struct LeaderboardEntry: Equatable {
        let position: Int
        let displayName: String
        let totalPoints: Int
        let pointsToday: Int
        let isCurrentUser: Bool
        let isTopThree: Bool
    }

    let competition: CompetitionOverview
    let currentUserId: String?

    init(competition: CompetitionOverview, currentUserId: String?) {
        self.competition = competition
        self.currentUserId = currentUserId
    }

    var competitionName: String {
        competition.competitionName
    }

    var isCompetitionActive: Bool {
        competition.isCompetitionActive
    }

    /// A compact position-and-time summary like "2nd place · 3d left" or "Not started" or "Ended".
    var userPositionDescription: String {
        let positionString = currentUserPositionString

        if !competition.hasCompetitionStarted {
            return "Starts \(WatchCompetitionDetailViewModel.relativeDateString(until: competition.startDate))"
        }

        if competition.hasCompetitionEnded {
            if let pos = positionString {
                return "Final · \(pos)"
            }
            return "Ended"
        }

        let remaining = WatchCompetitionDetailViewModel.relativeDateString(until: competition.endDate)
        if let pos = positionString {
            return "\(pos) place · \(remaining) left"
        }
        return "\(remaining) left"
    }

    /// The sorted leaderboard as value-typed entries ready for the view to render.
    var leaderboardEntries: [LeaderboardEntry] {
        let sorted = competition.currentResults.sorted()
        return sorted.enumerated().map { index, result in
            let position = index + 1
            return LeaderboardEntry(
                position: position,
                displayName: result.displayName,
                totalPoints: Int(result.totalPoints ?? 0),
                pointsToday: Int(result.pointsToday ?? 0),
                isCurrentUser: result.userId == currentUserId,
                isTopThree: position <= 3
            )
        }
    }

    private var currentUserPositionString: String? {
        guard let userId = currentUserId,
              let index = competition.currentResults.sorted().firstIndex(where: { $0.userId == userId })
        else { return nil }
        return WatchCompetitionDetailViewModel.ordinalString(for: index + 1)
    }

    static func ordinalString(for position: Int) -> String {
        let suffix: String
        switch position % 100 {
        case 11, 12, 13:
            suffix = "th"
        default:
            switch position % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(position)\(suffix)"
    }

    static func relativeDateString(until date: Date, now: Date = Date()) -> String {
        let interval = date.timeIntervalSince(now)
        if interval <= 0 { return "0d" }

        let days = Int(interval / 86_400)
        if days >= 7 {
            let weeks = days / 7
            return "\(weeks)w"
        }
        if days >= 1 {
            return "\(days)d"
        }
        let hours = max(1, Int(interval / 3_600))
        return "\(hours)h"
    }
}
