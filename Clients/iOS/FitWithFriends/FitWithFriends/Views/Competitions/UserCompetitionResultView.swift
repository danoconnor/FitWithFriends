//
//  UserCompetitionResultView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import SwiftUI

struct UserCompetitionResultView: View {
    let position: Int
    let result: UserCompetitionPoints

    private var positionBackgroundColor: Color {
        switch position {
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

                Text(position.description)
            }

            Text(result.displayName)
                .padding(.leading)
                .padding(.trailing)

            Spacer()

            Text("\(Int(result.totalPoints)) (\(Int(result.pointsToday ?? 0)))")
                .padding(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UserCompetitionResultView_Previews: PreviewProvider {
    static var previews: some View {
        UserCompetitionResultView(position: 1, result: UserCompetitionPoints())
    }
}
