//
//  UserCompetitionResultView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import SwiftUI

struct UserCompetitionResultView: View {
    let result: UserPosition
    let isCompetitionActive: Bool
    /// Unit to use when formatting the leaderboard values. Defaults to points to preserve legacy behaviour.
    var scoringUnit: ScoringUnit = .points

    private var positionBackgroundColor: Color {
        guard result.shouldShowPosition else {
            return Color(.tertiarySystemFill)
        }

        switch result.position {
        case 1: return Color.gold
        case 2: return Color.silver
        case 3: return Color.bronze
        default: return Color.clear
        }
    }

    private var isTopThree: Bool {
        result.shouldShowPosition && result.position <= 3
    }

    var body: some View {
        HStack(spacing: 12) {
            // Position indicator
            ZStack {
                if isTopThree {
                    Circle()
                        .fill(positionBackgroundColor)
                        .frame(width: 36, height: 36)
                } else {
                    Circle()
                        .stroke(Color(.separator), lineWidth: 1)
                        .frame(width: 36, height: 36)
                }

                if result.shouldShowPosition {
                    Text(result.position.description)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(isTopThree ? .white : .secondary)
                }
            }
            .frame(width: 36, height: 36)

            // Name and today's points
            VStack(alignment: .leading, spacing: 2) {
                Text(result.userCompetitionPoints.displayName)
                    .font(.body.weight(.medium))

                if isCompetitionActive, let todayPts = result.userCompetitionPoints.pointsToday, todayPts > 0 {
                    Text("+\(ScoringValueFormatter.format(todayPts, unit: scoringUnit)) today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Total score in the rule's native unit
            if let totalPoints = result.userCompetitionPoints.totalPoints {
                Text(ScoringValueFormatter.formatCompact(totalPoints, unit: scoringUnit))
                    .font(.title3.weight(.semibold).monospacedDigit())
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UserCompetitionResultView_Previews: PreviewProvider {
    static var previews: some View {
        UserCompetitionResultView(result: UserPosition(userCompetitionPoints: UserCompetitionPoints(), position: 1), isCompetitionActive: true)
    }
}
