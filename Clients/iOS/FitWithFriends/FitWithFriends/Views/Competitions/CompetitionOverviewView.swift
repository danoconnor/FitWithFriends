//
//  CompetitionDetailView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import Combine
import SwiftUI

struct CompetitionOverviewView: View {
    private let showAllDetails: Bool

    private let competitionOverview: CompetitionOverview
    private let homepageSheetViewModel: HomepageSheetViewModel
    @ObservedObject private var viewModel: CompetitionOverviewViewModel

    @State private var actionInProgress = false

    init(objectGraph: IObjectGraph, competitionOverview: CompetitionOverview, homepageSheetViewModel: HomepageSheetViewModel, showAllDetails: Bool) {
        self.competitionOverview = competitionOverview
        self.homepageSheetViewModel = homepageSheetViewModel
        self.showAllDetails = showAllDetails
        viewModel = CompetitionOverviewViewModel(authenticationManager: objectGraph.authenticationManager,
                                                 competitionManager: objectGraph.competitionManager,
                                                 competitionOverview: competitionOverview,
                                                 showAllDetails: showAllDetails)
    }

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Text(viewModel.competitionName)
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                    .padding(.trailing)
                    .padding(.top)
                    .onTapGesture {
                        if !self.showAllDetails {
                            self.homepageSheetViewModel.updateState(sheet: .competitionDetails,
                                                                    state: true,
                                                                    contextData: self.competitionOverview)
                        }
                    }
                

                Spacer()

                Menu {
                    ForEach(viewModel.availableActions.sorted(), id: \.self) { action in
                        Button(action.description) {
                            self.actionInProgress = true
                            Task.detached {
                                await self.viewModel.performAction(action)

                                await MainActor.run {
                                    self.actionInProgress = false
                                }
                            }
                        }
                        .disabled(actionInProgress)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .padding(.leading)
                        .padding(.trailing)
                        .padding(.top)
                }
            }

            HStack {
                Text(viewModel.userPositionDescription)
                    .padding(.leading)
                    .padding(.trailing)
                    .padding(.bottom)
                    .font(.subheadline)

                Spacer()

                Text(viewModel.competitionDatesDescription)
                    .padding(.leading)
                    .padding(.trailing)
                    .padding(.bottom)
                    .font(.subheadline)
            }

            VStack {
                ForEach(0 ..< viewModel.results.count, id: \.self) { position in
                    let result = viewModel.results[position]
                    UserCompetitionResultView(result: result)
                        .contextMenu {
                            let availableActions = self.viewModel.getUserContextMenuActions(for: result.userCompetitionPoints.userId)

                            ForEach(availableActions, id: \.self) { action in
                                Button(action.description) {
                                    Task.detached {
                                        await self.viewModel.performAction(action)
                                    }
                                }
                            }
                        }
                }
            }
            .padding()
        }
        .background(showAllDetails ? Color.systemBackground : Color.secondarySystemBackground)
        .sheet(isPresented: $viewModel.shouldShowSheet, content: {
            if let shareUrl = viewModel.shareUrl {
                ShareSheet(url: shareUrl)
            }
        })
        .alert(isPresented: $viewModel.shouldShowAlert) {
            // We currently only have one case where we show an alert:
            // when we want to confirm that the user wants to delete
            // a competition
            let titleText = Text("Are you sure?")
            let bodyText = Text("This will permanently delete the competition for all users.")
            let confirmButton: Alert.Button = .destructive(Text("Confirm")) {
                Task.detached {
                    await self.viewModel.deleteCompetitionConfirmed()
                }
            }

            return Alert(title: titleText,
                         message: bodyText,
                         primaryButton: .cancel(),
                         secondaryButton: confirmButton)
        }
    }
}

struct CompetitionOverviewView_Previews: PreviewProvider {
    private static var competitionOverview: CompetitionOverview {
        let results = [
            UserCompetitionPoints(userId: "user_0", firstName: "Test", lastName: "User 0", total: 400, today: 110),
            UserCompetitionPoints(userId: "user_1", firstName: "Test", lastName: "User 1", total: 300, today: 125),
            UserCompetitionPoints(userId: "user_2", firstName: "Test", lastName: "User 2", total: 425, today: 75),
            UserCompetitionPoints(userId: "user_3", firstName: "Test", lastName: "User 3", total: 100, today: 0),
            UserCompetitionPoints(userId: "user_4", firstName: "Test", lastName: "User 4", total: 50, today: 0),
            UserCompetitionPoints(userId: "user_5", firstName: "Test", lastName: "User 5", total: 10, today: 10)
        ]

        return CompetitionOverview(start: Date(),
                                   end: Date().addingTimeInterval(TimeInterval.xtDays(7)),
                                   currentResults: results)
    }

    static var previews: some View {
        CompetitionOverviewView(objectGraph: MockObjectGraph(),
                                competitionOverview: competitionOverview, homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(), healthKitManager: MockHealthKitManager()),
                                showAllDetails: true)

        CompetitionOverviewView(objectGraph: MockObjectGraph(),
                                competitionOverview: competitionOverview, homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(), healthKitManager: MockHealthKitManager()),
                                showAllDetails: false)
    }
}
