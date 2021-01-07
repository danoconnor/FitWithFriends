//
//  CompetitionSummaryView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/3/21.
//

import SwiftUI

struct CompetitionSummaryView: View {
    //let competitionOverview: CompetitionOverview

    var body: some View {
        VStack {
            Text("Competition name")
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .padding(.trailing)
                .padding(.top)

            Text("3rd")
                .font(.largeTitle)
                .background(Circle().fill(Color.green).frame(width: 200, height: 200))

            ZStack {
                Circle()
                    .fill(Color.red)
                    .padding(20)
                    .frame(width: 200, height: 200)

                Text("3rd")
                    .font(.system(size: 75))
            }


            Spacer()
        }
        .background(Color.secondary)
    }
}

struct CompetitionSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        CompetitionSummaryView()
    }
}
