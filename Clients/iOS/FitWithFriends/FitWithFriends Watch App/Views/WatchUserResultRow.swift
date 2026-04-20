//
//  WatchUserResultRow.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import SwiftUI

struct WatchUserResultRow: View {
    let entry: WatchCompetitionDetailViewModel.LeaderboardEntry
    let isCompetitionActive: Bool

    private var positionBackgroundColor: Color {
        switch entry.position {
        case 1: return Color.gold
        case 2: return Color.silver
        case 3: return Color.bronze
        default: return Color.clear
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            positionBadge
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 0) {
                Text(entry.displayName)
                    .font(.caption.weight(entry.isCurrentUser ? .bold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if isCompetitionActive && entry.pointsToday > 0 {
                    Text("+\(entry.pointsToday) today")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("\(entry.totalPoints)")
                .font(.footnote.weight(.semibold).monospacedDigit())
        }
        .accessibilityIdentifier("userRow_\(entry.displayName)")
    }

    @ViewBuilder
    private var positionBadge: some View {
        ZStack {
            if entry.isTopThree {
                Circle()
                    .fill(positionBackgroundColor)
            } else {
                Circle()
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
            }
            Text("\(entry.position)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(entry.isTopThree ? Color.white : Color.secondary)
        }
    }
}
