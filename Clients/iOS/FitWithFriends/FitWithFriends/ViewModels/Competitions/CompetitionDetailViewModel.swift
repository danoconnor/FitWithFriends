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

    init(authenticationManager: AuthenticationManager,
         competitionOverview: CompetitionOverview) {
        self.authenticationManager = authenticationManager
        self.competitionOverview = competitionOverview
    }
}
