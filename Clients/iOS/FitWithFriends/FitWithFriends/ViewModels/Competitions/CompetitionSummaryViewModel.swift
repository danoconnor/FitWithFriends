//
//  CompetitionSummaryViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/18/21.
//

import Foundation
import SwiftUI

class CompetitionSummaryViewModel {
    public let competitionName: String
    public let status: String
    public let userPosition: Int
    public let userPositionColor: Color
    public let showScoreboard: Bool
    private(set) public var leaderBoard: [String]

    private let competitionOverview: CompetitionOverview

    init(authenticationManager: AuthenticationManager, competitionOverview: CompetitionOverview) {
        self.competitionOverview = competitionOverview

        competitionName = competitionOverview.competitionName

        if competitionOverview.competitionStart > Date() {
            let days = Date().timeIntervalSince(competitionOverview.competitionStart).xtDays
            if days <= 1 {
                status = "Competition starts tomorrow!"
            } else {
                status = "Competition starts in \(days) days"
            }
        } else {
            let days = competitionOverview.competitionEnd.timeIntervalSince(Date()).xtDays
            if days < 0 {
                status = "Competition ended"
            } else if days == 0 {
                status = "Last day!"
            } else if days == 1 {
                status = "1 day remaining"
            } else {
                status = "\(days) days remaining"
            }
        }

        let orderedResults = competitionOverview.currentResults.sorted { $0.totalPoints > $1.totalPoints }
        showScoreboard = orderedResults.count > 0

        let userPositionIndex = orderedResults.firstIndex { $0.userId == authenticationManager.loggedInUserId } ?? orderedResults.count - 1
        userPosition = userPositionIndex + 1

        switch userPosition {
        case 1:
            userPositionColor = Color.gold
        case 2:
            userPositionColor = Color.silver
        case 3:
            userPositionColor = Color.bronze
        default:
            userPositionColor = Color.gray
        }

        leaderBoard = []
        let leaderBoardFormat = "%d. %@ (%d)"
        for i in 0 ... 2 {
            if i >= orderedResults.count {
                break
            }

            let result = orderedResults[i]
            leaderBoard.append(String(format: leaderBoardFormat, i + 1, result.displayName, Int(result.totalPoints)))
        }

        if userPosition > 3 {
            let userResult = orderedResults[userPositionIndex]
            leaderBoard.append(String(format: leaderBoardFormat, userPosition, userResult.displayName, Int(userResult.totalPoints)))
        }
    }
}
