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

    private let maxCompetitionLengthInDays: Double = 30;

    init(homepageSheetViewModel: HomepageSheetViewModel, objectGraph: IObjectGraph) {
        viewModel = CreateCompetitionViewModel(authenticationManager: objectGraph.authenticationManager,
                                               competitionManager: objectGraph.competitionManager,
                                               homepageSheetViewModel: homepageSheetViewModel)
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.state.isFailed {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.circle")

                            Text(viewModel.state.errorMessage)
                                .font(.subheadline)

                            Spacer()
                        }
                        .padding()
                    }
                    .background(Color.red)
                }

                TextField("Competition name", text: $competitionName)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                DatePicker("Start date",
                           selection: $startDate,
                           displayedComponents: .date)
                    .padding()

                DatePicker("End date",
                           selection: $endDate,
                           in: ClosedRange(uncheckedBounds: (startDate + .xtDays(1), startDate + .xtDays(maxCompetitionLengthInDays))),
                           displayedComponents: .date)
                    .padding()

                Spacer()

                Button("Create") {
                    viewModel.createCompetition(competitionName: competitionName,
                                                startDate: startDate,
                                                endDate: endDate)
                }
                .font(.title2)
                .padding()
                .disabled(viewModel.state == .inProgress || competitionName.count == 0)
            }
            .navigationTitle("Create competition")
        }
    }
}

struct CreateCompetitionView_Previews: PreviewProvider {
    static var previews: some View {
        CreateCompetitionView(homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(),
                                                                             healthKitManager: MockHealthKitManager()),
        objectGraph: MockObjectGraph())
    }
}
