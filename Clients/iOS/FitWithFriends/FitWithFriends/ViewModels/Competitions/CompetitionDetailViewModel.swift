//
//  CompetitionDetailViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/4/21.
//

import Foundation

class CompetitionDetailViewModel {
    private let authenticationManager: AuthenticationManager
    private let competitionOverview: CompetitionOverview

    let competitionName: String
    let userPositionDescription: String
    let results: [UserCompetitionPoints]

    init(authenticationManager: AuthenticationManager,
         competitionOverview: CompetitionOverview) {
        self.authenticationManager = authenticationManager
        self.competitionOverview = competitionOverview

        competitionName = competitionOverview.competitionName

        let currentResults = competitionOverview.currentResults.sorted { $0.totalPoints > $1.totalPoints }
        results = currentResults

        // Find the user's current position in the results
        let userPosition = currentResults.firstIndex { $0.userId == authenticationManager.loggedInUserId } ?? -1 + 1
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

        userPositionDescription = "You're in \(userPosition)\(userPositionString)"
    }
}
