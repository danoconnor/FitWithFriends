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
            Group {
                Text(position.description)
                    .padding(.leading)
                    .padding(.bottom, 10)
                    .padding(.top, 10)
                    .padding(.trailing)
            }
            .background(positionBackgroundColor)
            .cornerRadius(100)

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
