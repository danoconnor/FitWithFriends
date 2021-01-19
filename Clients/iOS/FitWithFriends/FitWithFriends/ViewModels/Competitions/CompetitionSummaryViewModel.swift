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
    public let daysLeft: String
    public let userPosition: Int
    public let userPositionColor: Color
    private(set) public var leaderBoard: [String]

    private let competitionOverview: CompetitionOverview

    init(authenticationManager: AuthenticationManager, competitionOverview: CompetitionOverview) {
        self.competitionOverview = competitionOverview

        competitionName = competitionOverview.competitionName

        let days = competitionOverview.competitionEnd.timeIntervalSince(Date()).xtDays
        if days < 0 {
            daysLeft = "Competition ended"
        }
        else if days == 0 {
            daysLeft = "Last day!"
        } else if days == 1 {
            daysLeft = "1 day remaining"
        } else {
            daysLeft = "\(days) days remaining"
        }

        let orderedResults = competitionOverview.currentResults.sorted { $0.totalPoints > $1.totalPoints }

        // Force unwrap here since the logged in user must be a member of any competiion shown
        let userPositionIndex = orderedResults.firstIndex { $0.userId == authenticationManager.loggedInUserId }!
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
