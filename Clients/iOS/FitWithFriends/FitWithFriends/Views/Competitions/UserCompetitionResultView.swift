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
    /// Unit used when formatting the leaderboard values. Defaults to points for legacy callers.
    var scoringUnit: ScoringUnit = .points
    /// `true` when the row represents the currently logged-in user. Drives the
    /// brand-tinted highlight on the competition detail leaderboard.
    var isCurrentUser: Bool = false

    private var medalColor: Color? {
        guard result.shouldShowPosition else { return nil }
        switch result.position {
        case 1: return Color("Gold")
        case 2: return Color("Silver")
        case 3: return Color("Bronze")
        default: return nil
        }
    }

    private var isTopThree: Bool {
        medalColor != nil
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank chip — filled for medals, hairline circle for everyone else.
            ZStack {
                if let medalColor {
                    Circle().fill(medalColor)
                } else {
                    Circle().strokeBorder(Color("Border"), lineWidth: 1)
                }

                if result.shouldShowPosition {
                    Text(result.position.description)
                        .font(.system(size: 14, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(isTopThree ? .white : Color("InkSoft"))
                }
            }
            .frame(width: 32, height: 32)

            FWFAvatar(name: result.userCompetitionPoints.displayName, size: 32)

            // Name and today's points
            VStack(alignment: .leading, spacing: 2) {
                Text(isCurrentUser ? "You" : result.userCompetitionPoints.displayName)
                    .font(.system(size: 15, weight: isCurrentUser ? .bold : .semibold))
                    .foregroundStyle(Color("Ink"))

                if isCompetitionActive, let todayPts = result.userCompetitionPoints.pointsToday, todayPts > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color("Exercise"))
                        Text("+\(ScoringValueFormatter.format(todayPts, unit: scoringUnit)) today")
                            .font(.system(size: 12))
                            .foregroundStyle(Color("InkSoft"))
                    }
                }
            }

            Spacer()

            // Total score in the rule's native unit
            if let totalPoints = result.userCompetitionPoints.totalPoints {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(ScoringValueFormatter.formatCompact(totalPoints, unit: scoringUnit))
                        .font(.system(size: 20, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(Color("Ink"))
                    Text(unitSuffix)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color("InkMute"))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isCurrentUser ? Color("BrandSoft") : Color("Surface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isCurrentUser ? Color("Brand") : Color("Border"),
                              lineWidth: isCurrentUser ? 1.5 : 1)
        )
        .shadow(color: isCurrentUser ? Color("Brand").opacity(0.18) : .clear, radius: 8, x: 0, y: 4)
    }

    private var unitSuffix: String {
        switch scoringUnit {
        case .points: return "pts"
        case .steps: return "steps"
        case .kcal: return "kcal"
        case .minutes: return "min"
        case .meters: return ""
        }
    }
}

struct UserCompetitionResultView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 8) {
            UserCompetitionResultView(
                result: UserPosition(userCompetitionPoints: UserCompetitionPoints(firstName: "Alice", lastName: "Chen", total: 480, today: 110), position: 1),
                isCompetitionActive: true,
                isCurrentUser: false
            )
            UserCompetitionResultView(
                result: UserPosition(userCompetitionPoints: UserCompetitionPoints(firstName: "You", lastName: "", total: 422, today: 235), position: 2),
                isCompetitionActive: true,
                isCurrentUser: true
            )
            UserCompetitionResultView(
                result: UserPosition(userCompetitionPoints: UserCompetitionPoints(firstName: "Sam", lastName: "Smith", total: 100, today: 0), position: 4),
                isCompetitionActive: true,
                isCurrentUser: false
            )
        }
        .padding()
        .background(Color("Bg"))
    }
}
