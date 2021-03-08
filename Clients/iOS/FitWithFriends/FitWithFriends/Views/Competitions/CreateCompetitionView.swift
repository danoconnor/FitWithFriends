//
//  CreateCompetitionView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/27/21.
//

import SwiftUI

struct CreateCompetitionView: View {
    @ObservedObject private var viewModel: CreateCompetitionViewModel

    @State var startDate = Date().addingTimeInterval(TimeInterval.xtDays(1))
    @State var endDate = Date().addingTimeInterval(TimeInterval.xtDays(8))
    @State var competitionName = ""
    @State var workoutsOnly = false

    init(homepageSheetViewModel: HomepageSheetViewModel) {
        viewModel = CreateCompetitionViewModel(authenticationManager: ObjectGraph.sharedInstance.authenticationManager,
                                               competitionManager: ObjectGraph.sharedInstance.competitionManager,
                                               homepageSheetViewModel: homepageSheetViewModel)
    }

    var body: some View {
        VStack {
            Spacer()

            Text("Create a new competition")
                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                .padding()

            TextField("Competition name", text: $competitionName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            DatePicker("Start date",
                       selection: $startDate,
                       displayedComponents: .date)
                .padding()

            DatePicker("End date",
                       selection: $endDate,
                       displayedComponents: .date)
                .padding()

            Toggle("Only workouts count for points", isOn: $workoutsOnly)
                .padding()

            Spacer()
            Spacer()

            if viewModel.state.isFailed {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .padding(.leading)

                    Text(viewModel.state.errorMessage)
                        .font(.subheadline)
                        .padding(.trailing)

                    Spacer()
                }
                .background(Color.red)
            }

            Button("Create") {
                viewModel.createCompetition(competitionName: competitionName,
                                            startDate: startDate,
                                            endDate: endDate,
                                            workoutsOnly: workoutsOnly)
            }
            .font(.title2)
            .padding()
            .disabled(viewModel.state == .inProgress || competitionName.count == 0)
        }
    }
}

struct CreateCompetitionView_Previews: PreviewProvider {
    static var previews: some View {
        CreateCompetitionView(homepageSheetViewModel: HomepageSheetViewModel())
    }
}
