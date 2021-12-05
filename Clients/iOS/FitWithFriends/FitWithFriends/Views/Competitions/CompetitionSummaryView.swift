//
//  CompetitionSummaryView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/3/21.
//

import SwiftUI

struct CompetitionSummaryView: View {
    private let authenticationManager: AuthenticationManager
    private let competitionOverview: CompetitionOverview

    private let competitionSummaryViewModel: CompetitionSummaryViewModel

    @State var showDetailsSheet = false

    init(authenticationManager: AuthenticationManager, competitionOverview: CompetitionOverview) {
        self.authenticationManager = authenticationManager
        self.competitionOverview = competitionOverview

        self.competitionSummaryViewModel = CompetitionSummaryViewModel(authenticationManager: authenticationManager,
                                                                       competitionOverview: competitionOverview)
    }

    var body: some View {
        VStack {
            Text(competitionSummaryViewModel.competitionName)
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .padding(.trailing)
                .padding(.top)

            Text(competitionSummaryViewModel.status)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .padding(.trailing)

            if competitionSummaryViewModel.showScoreboard {
                HStack {
                    ZStack {
                        Circle()
                            .fill(competitionSummaryViewModel.userPositionColor)
                            .frame(width: 40, height: 40)

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
            }

            Spacer()
        }
        .cornerRadius(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
        .onTapGesture {
            showDetailsSheet = true
        }
        .sheet(isPresented: $showDetailsSheet, content: {
            CompetitionDetailView(authenticationManager: authenticationManager,
                                  competitionOverview: competitionOverview)
        })
    }
}

//struct CompetitionSummaryView_Previews: PreviewProvider {
//    static var previews: some View {
//        CompetitionSummaryView()
//    }
//}
