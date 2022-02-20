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
    let competitionDatesDescription: String
    let results: [UserCompetitionPoints]

    init(authenticationManager: AuthenticationManager,
         competitionOverview: CompetitionOverview) {
        self.authenticationManager = authenticationManager
        self.competitionOverview = competitionOverview

        competitionName = competitionOverview.competitionName

        let currentResults = competitionOverview.currentResults.sorted { $0.totalPoints > $1.totalPoints }
        results = currentResults

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        let startString = dateFormatter.string(from: competitionOverview.competitionStart)
        let endString = dateFormatter.string(from: competitionOverview.competitionEnd)
        competitionDatesDescription = "\(startString) - \(endString)"

        // Find the user's current position in the results
        let userPositionZeroIndex = currentResults.firstIndex { $0.userId == authenticationManager.loggedInUserId } ?? -1
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

        let userPositionPrefix = Date() > competitionOverview.competitionEnd ? "You finished in" : "You're in"

        userPositionDescription = "\(userPositionPrefix) \(userPosition)\(userPositionString)"
    }
}
