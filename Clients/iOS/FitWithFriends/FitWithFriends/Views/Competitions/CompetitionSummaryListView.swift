//
//  CompetitionSummaryListView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/3/21.
//

import SwiftUI

struct CompetitionSummaryListView: View {
    @ObservedObject var competitionsManager = ObjectGraph.sharedInstance.competitionManager

    var body: some View {
        List(competitionsManager.competitionOverviews.map({ $0.1 })) { overview in
            //CompetitionSummaryView(competitionOverview: overview)
        }
    }
}

struct CompetitionSummaryListView_Previews: PreviewProvider {
    static var previews: some View {
        CompetitionSummaryListView()
    }
}
