//
//  CompetitionsPagerView.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import SwiftUI

struct CompetitionsPagerView: View {
    let overviews: [CompetitionOverview]
    let currentUserId: String?
    let onRefresh: () async -> Void

    var body: some View {
        TabView {
            ForEach(overviews, id: \.competitionId) { overview in
                NavigationLink {
                    WatchCompetitionDetailView(
                        viewModel: WatchCompetitionDetailViewModel(
                            competition: overview,
                            currentUserId: currentUserId
                        )
                    )
                } label: {
                    CompetitionCardView(
                        viewModel: WatchCompetitionDetailViewModel(
                            competition: overview,
                            currentUserId: currentUserId
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .tabViewStyle(.page)
        .refreshable {
            await onRefresh()
        }
        .accessibilityIdentifier("competitionsPager")
    }
}
