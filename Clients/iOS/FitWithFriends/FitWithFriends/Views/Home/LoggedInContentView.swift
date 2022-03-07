//
//  LoggedInContentView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/20.
//

import HealthKitUI
import SwiftUI

struct LoggedInContentView: View {
    private let objectGraph: IObjectGraph

    private var lastShownSheet: HomepageSheetViewModel.HomepageSheet?

    @ObservedObject private var homepageSheetViewModel: HomepageSheetViewModel
    @ObservedObject private var homepageViewModel: HomepageViewModel

    init(objectGraph: IObjectGraph) {
        self.objectGraph = objectGraph
        homepageSheetViewModel = HomepageSheetViewModel(appProtocolHandler: objectGraph.appProtocolHandler,
                                                        healthKitManager: objectGraph.healthKitManager)
        homepageViewModel = HomepageViewModel(competitionManager: objectGraph.competitionManager,
                                              healthKitManager: objectGraph.healthKitManager)
    }

    var body: some View {
        RefreshableScrollView {
            VStack {
                if let activitySummary = homepageViewModel.todayActivitySummary {
                    TodaySummaryView(activitySummary: activitySummary)
                        .cornerRadius(10)
                        .padding(.top)
                        .padding(.leading)
                        .padding(.trailing)
                }

                if let competitions = homepageViewModel.currentCompetitions {
                    ForEach(competitions) { competitionOverview in
                        CompetitionOverviewView(objectGraph: objectGraph,
                                                competitionOverview: competitionOverview,
                                                homepageSheetViewModel: homepageSheetViewModel,
                                                showAllDetails: false)
                            .cornerRadius(10)
                            .padding()
                    }
                }

                Spacer()

                Button(action: {
                    homepageSheetViewModel.updateState(sheet: .createCompetition, state: true)
                }, label: {
                    Text("New competition")
                })
                .padding()

                Button(action: {
                    objectGraph.authenticationManager.logout()
                }, label: {
                    Text("Logout")
                })
                .padding()
            }
            .sheet(isPresented: $homepageSheetViewModel.shouldShowSheet, onDismiss: {
                homepageSheetViewModel.dismissCurrentSheet()
            }, content: {
                switch homepageSheetViewModel.sheetToShow {
                case .createCompetition:
                    CreateCompetitionView(homepageSheetViewModel: homepageSheetViewModel,
                                          objectGraph: objectGraph)
                case .permissionPrompt:
                    PermissionPromptView(homepageSheetViewModel: homepageSheetViewModel,
                                         objectGraph: objectGraph)
                case .joinCompetition:
                    JoinCompetitionView(homepageSheetViewModel: homepageSheetViewModel,
                                        objectGraph: objectGraph)
                case .competitionDetails:
                    if let competitionOverview = homepageSheetViewModel.sheetContextData as? CompetitionOverview {
                        CompetitionDetailView(competitionOverview: competitionOverview,
                                              homepageSheetViewModel: homepageSheetViewModel,
                                              objectGraph: objectGraph)
                    } else {
                        Text("Error showing competition details")
                    }
                default:
                    Text("Unknown sheet type: \(homepageSheetViewModel.sheetToShow.rawValue)")
                }
            })
        } onRefresh: {
            await homepageViewModel.refreshData()
        }
    }
}

struct LoggedInContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedInContentView(objectGraph: MockObjectGraph())
    }
}
