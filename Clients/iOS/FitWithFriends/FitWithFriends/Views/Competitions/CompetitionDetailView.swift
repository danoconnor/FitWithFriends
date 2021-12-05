//
//  CompetitionDetailView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/4/21.
//

import SwiftUI

struct CompetitionDetailView: View {
    private let authenticationManager: AuthenticationManager
    private let competitionOverview: CompetitionOverview

    private let competitionDetailViewModel: CompetitionDetailViewModel

    init(authenticationManager: AuthenticationManager, competitionOverview: CompetitionOverview) {
        self.authenticationManager = authenticationManager
        self.competitionOverview = competitionOverview

        self.competitionDetailViewModel = CompetitionDetailViewModel(authenticationManager: authenticationManager,
                                                                       competitionOverview: competitionOverview)
    }

    var body: some View {
        Text("Showing details for \(competitionOverview.competitionName)")
    }
}

//struct CompetitionDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        CompetitionDetailView()
//    }
//}
