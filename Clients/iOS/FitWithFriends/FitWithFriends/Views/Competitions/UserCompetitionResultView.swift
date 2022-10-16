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

    private var positionBackgroundColor: Color {
        guard result.shouldShowPosition else {
            return Color.clear
        }

        switch result.position {
        case 1: return Color.gold
        case 2: return Color.silver
        case 3: return Color.bronze
        default: return Color.clear
        }
    }

    var body: some View {
        HStack {
            // TODO: how to handle different text sizes?
            ZStack {
                Circle()
                    .frame(width: 40, height: 40)
                    .foregroundColor(positionBackgroundColor)

                if result.shouldShowPosition {
                    Text(result.position.description)
                }
            }

            Text(result.userCompetitionPoints.displayName)
                .padding(.leading)
                .padding(.trailing)

            Spacer()

            if let totalPoints = result.userCompetitionPoints.totalPoints {
                if isCompetitionActive {
                    Text("\(Int(totalPoints)) (\(Int(result.userCompetitionPoints.pointsToday ?? 0)))")
                        .padding(.leading)
                } else {
                    // Don't include the points scored today if the competition is not active
                    Text("\(Int(totalPoints))")
                        .padding(.leading)
                }


            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UserCompetitionResultView_Previews: PreviewProvider {
    static var previews: some View {
        UserCompetitionResultView(result: UserPosition(userCompetitionPoints: UserCompetitionPoints(), position: 1), isCompetitionActive: true)
    }
}
