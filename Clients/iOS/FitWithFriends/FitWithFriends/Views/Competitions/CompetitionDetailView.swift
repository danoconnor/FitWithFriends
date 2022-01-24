//
//  CompetitionDetailView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import SwiftUI

struct CompetitionDetailView: View {
    private let viewModel: CompetitionDetailViewModel

    init(objectGraph: IObjectGraph, competitionOverview: CompetitionOverview) {
        viewModel = CompetitionDetailViewModel(authenticationManager: objectGraph.authenticationManager,
                                               competitionOverview: competitionOverview)
    }

    var body: some View {
        VStack {
            Text(viewModel.competitionName)
                .padding(.leading)
                .padding(.trailing)
                .padding(.top)
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(viewModel.userPositionDescription)
                .padding(.leading)
                .padding(.trailing)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(0 ..< viewModel.results.count) {
                UserCompetitionResultView(position: $0 + 1, result: viewModel.results[$0])
            }
            .padding(.leading)
            .padding(.trailing)
            .padding(.top)
        }
        .background(Color.secondarySystemBackground)
    }
}

struct CompetitionDetailView_Previews: PreviewProvider {
    private static var competitionOverview: CompetitionOverview {
        let results = [
            UserCompetitionPoints(userId: 1, name: "Test user 1", total: 300, today: 125),
            UserCompetitionPoints(userId: 2, name: "Test user 2", total: 425, today: 75),
            UserCompetitionPoints(userId: 3, name: "Test user 3", total: 100, today: 0),
            UserCompetitionPoints(userId: 4, name: "Test user 4", total: 50, today: 0),
            UserCompetitionPoints(userId: 5, name: "Test user 5", total: 10, today: 10)
        ]

        return CompetitionOverview(start: Date(),
                                   end: Date().addingTimeInterval(TimeInterval.xtDays(7)),
                                   currentResults: results)
    }

    static var previews: some View {
        CompetitionDetailView(objectGraph: MockObjectGraph(),
                              competitionOverview: competitionOverview)
    }
}
