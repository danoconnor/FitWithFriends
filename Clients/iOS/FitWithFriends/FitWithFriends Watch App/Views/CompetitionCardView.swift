//
//  CompetitionCardView.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import SwiftUI

struct CompetitionCardView: View {
    let viewModel: WatchCompetitionDetailViewModel

    private var topThree: [WatchCompetitionDetailViewModel.LeaderboardEntry] {
        Array(viewModel.leaderboardEntries.prefix(3))
    }

    private var currentUserEntry: WatchCompetitionDetailViewModel.LeaderboardEntry? {
        viewModel.leaderboardEntries.first(where: { $0.isCurrentUser })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.competitionName)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                heroBlock

                if !topThree.isEmpty {
                    Divider()
                    VStack(spacing: 4) {
                        ForEach(topThree, id: \.position) { entry in
                            WatchUserResultRow(entry: entry, isCompetitionActive: viewModel.isCompetitionActive)
                        }
                    }
                }

                Text(viewModel.userPositionDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .accessibilityIdentifier("competitionCard_\(viewModel.competitionName)")
    }

    @ViewBuilder
    private var heroBlock: some View {
        VStack(spacing: 2) {
            if let currentUser = currentUserEntry {
                Text(WatchCompetitionDetailViewModel.ordinalString(for: currentUser.position))
                    .font(.system(.title2, design: .rounded).weight(.bold).monospacedDigit())
                Text("\(currentUser.totalPoints) points")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                if viewModel.isCompetitionActive && currentUser.pointsToday > 0 {
                    Text("+\(currentUser.pointsToday) today")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Color("FwFBrandingColor"))
                }
            } else {
                Text("—")
                    .font(.title2.weight(.bold))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color("FwFBrandingColor").opacity(0.15))
        )
    }
}
