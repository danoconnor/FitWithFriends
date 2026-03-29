//
//  CompetitionDetailView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/5/22.
//

import SwiftUI

struct CompetitionDetailView: View {
    private let competitionOverview: CompetitionOverview
    private let homepageSheetViewModel: HomepageSheetViewModel
    private let objectGraph: IObjectGraph
    private let viewModel: CompetitionDetailViewModel

    init(competitionOverview: CompetitionOverview,
         homepageSheetViewModel: HomepageSheetViewModel,
         objectGraph: IObjectGraph) {
        self.competitionOverview = competitionOverview
        self.homepageSheetViewModel = homepageSheetViewModel
        self.objectGraph = objectGraph

        viewModel = CompetitionDetailViewModel(competitionManager: objectGraph.competitionManager,
                                               homepageSheetViewModel: homepageSheetViewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                CompetitionOverviewView(objectGraph: objectGraph,
                                        competitionOverview: competitionOverview,
                                        homepageSheetViewModel: homepageSheetViewModel,
                                        showAllDetails: true)
                    .fwfCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
            }
            .navigationTitle("Competition Details")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDragIndicator(.visible)
    }
}

struct CompetitionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CompetitionDetailView(competitionOverview: CompetitionOverview(),
                              homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(), healthKitManager: MockHealthKitManager()),
                              objectGraph: MockObjectGraph())
    }
}
