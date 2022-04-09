//
//  UserCompetitionResultView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import SwiftUI

struct UserCompetitionResultView: View {
    let result: UserPosition

    private var positionBackgroundColor: Color {
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

                Text(result.position.description)
            }

            Text(result.userCompetitionPoints.displayName)
                .padding(.leading)
                .padding(.trailing)

            Spacer()

            if let totalPoints = result.userCompetitionPoints.totalPoints {
                Text("\(Int(totalPoints)) (\(Int(result.userCompetitionPoints.pointsToday ?? 0)))")
                    .padding(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UserCompetitionResultView_Previews: PreviewProvider {
    static var previews: some View {
        UserCompetitionResultView(result: UserPosition(userCompetitionPoints: UserCompetitionPoints(), position: 1))
    }
}
