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
        let overviews = competitionsManager.competitionOverviews
            .map { $0.1 }
            .sorted { $0.competitionStart > $1.competitionStart }

        List(overviews) { overview in
            CompetitionSummaryView(authenticationManager: ObjectGraph.sharedInstance.authenticationManager,
                                   competitionOverview: overview)
        }
    }
}

struct CompetitionSummaryListView_Previews: PreviewProvider {
    static var previews: some View {
        CompetitionSummaryListView()
    }
}
