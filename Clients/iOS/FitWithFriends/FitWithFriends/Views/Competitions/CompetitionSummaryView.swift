//
//  CompetitionSummaryView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/3/21.
//

import SwiftUI

struct CompetitionSummaryView: View {
    let competitionSummaryViewModel: CompetitionSummaryViewModel

    var body: some View {
        VStack {
            Text(competitionSummaryViewModel.competitionName)
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .padding(.trailing)
                .padding(.top)

            Text(competitionSummaryViewModel.daysLeft)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .padding(.trailing)

            HStack {
                ZStack {
                    Circle()
                        .fill(competitionSummaryViewModel.userPositionColor)
                        .frame(width: 50, height: 50)

                    Text(competitionSummaryViewModel.userPosition.description)
                        .font(.largeTitle)
                }

                VStack {
                    ForEach(competitionSummaryViewModel.leaderBoard, id: \.self) { result in
                        HStack {
                            Text(result)
                            Spacer()
                        }
                    }
                }
                .padding(.leading)
            }
            .padding(.top, 2)
            .padding(.leading)
            .padding(.trailing)

            Spacer()
        }
        .cornerRadius(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
    }
}

//struct CompetitionSummaryView_Previews: PreviewProvider {
//    static var previews: some View {
//        CompetitionSummaryView()
//    }
//}
