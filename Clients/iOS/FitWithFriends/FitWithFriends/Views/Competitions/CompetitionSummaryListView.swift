//
//  CompetitionSummaryListView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/3/21.
//

import SwiftUI
import UIKit

struct CompetitionSummaryListView: View {
    @ObservedObject var competitionsManager = ObjectGraph.sharedInstance.competitionManager

    init() {
        // Hack to change the background color of the list
        // SwiftUI lists are implemented as UITableViews, so change the appearance of all UITableViews
        UITableView.appearance().backgroundColor = UIColor.secondarySystemBackground
    }

    var body: some View {
        List(competitionsManager.competitionOverviews.map({ $0.1 })) { overview in
            let overviewVM = CompetitionSummaryViewModel(authenticationManager: ObjectGraph.sharedInstance.authenticationManager,
                                                         competitionOverview: overview)
            CompetitionSummaryView(competitionSummaryViewModel: overviewVM)
        }
    }
}

struct CompetitionSummaryListView_Previews: PreviewProvider {
    static var previews: some View {
        CompetitionSummaryListView()
    }
}
