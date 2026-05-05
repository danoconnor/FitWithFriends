//
//  WatchCompetitionDetailView.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import SwiftUI

struct WatchCompetitionDetailView: View {
    let viewModel: WatchCompetitionDetailViewModel

    var body: some View {
        List {
            Section {
                ForEach(viewModel.leaderboardEntries, id: \.position) { entry in
                    WatchUserResultRow(entry: entry, isCompetitionActive: viewModel.isCompetitionActive)
                }
            } header: {
                Text(viewModel.userPositionDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        #if os(watchOS)
        .listStyle(.carousel)
        #endif
        .navigationTitle(viewModel.competitionName)
        .accessibilityIdentifier("competitionDetailView")
    }
}
