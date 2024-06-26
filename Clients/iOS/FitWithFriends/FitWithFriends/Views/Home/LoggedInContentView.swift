//
//  LoggedInContentView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/20.
//

import HealthKitUI
import Refresher
import SwiftUI

struct LoggedInContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    private let objectGraph: IObjectGraph

    @ObservedObject private var homepageSheetViewModel: HomepageSheetViewModel
    @ObservedObject private var homepageViewModel: HomepageViewModel

    init(objectGraph: IObjectGraph) {
        self.objectGraph = objectGraph
        homepageSheetViewModel = HomepageSheetViewModel(appProtocolHandler: objectGraph.appProtocolHandler,
                                                        healthKitManager: objectGraph.healthKitManager)
        homepageViewModel = HomepageViewModel(authenticationManager: objectGraph.authenticationManager,
                                              competitionManager: objectGraph.competitionManager,

                                              healthKitManager: objectGraph.healthKitManager)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if let activitySummary = homepageViewModel.todayActivitySummary {
                        TodaySummaryView(activitySummary: activitySummary,
                                         homepageSheetViewModel: homepageSheetViewModel,
                                         objectGraph: objectGraph)
                            .cornerRadius(10)
                            .padding(.top)
                            .padding(.leading)
                            .padding(.trailing)
                    } else if homepageViewModel.loadedActivitySummary {
                        // We have completed the call to HealthKit but there is no data returned
                        // We probably don't have health data access, so show the user some troubleshooting message
                        VStack {
                            Text("We're having trouble reading your activity information. Please check permissions in iOS Settings > Privacy > Health > Fit w/ Friends.")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.secondarySystemBackground)
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
                                .padding(.top)
                                .padding(.leading)
                                .padding(.trailing)
                        }
                    }

                    HStack {
                        Spacer()

                        Button(action: {
                            homepageSheetViewModel.updateState(sheet: .createCompetition, state: true)
                        }, label: {
                            Text("Create new competition")
                        })
                        .padding()

                        Spacer()
                    }
                    .background(Color.secondarySystemBackground)
                    .cornerRadius(10)
                    .padding()

                    Spacer()
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
                    case .about:
                        AboutView(emailUtility: objectGraph.emailUtility,
                                  serverEnvironmentManager: objectGraph.serverEnvironmentManager)
                    default:
                        Text("Unknown sheet type: \(homepageSheetViewModel.sheetToShow.rawValue)")
                    }
                })
            }
            .refreshable {
                await homepageViewModel.refreshData()
            }
            .navigationTitle("Fit with Friends")
            .navigationBarColor(backgroundColor: UIColor(named: "FwFBrandingColor"))
            .toolbar {
                Menu {
                    Button("Logout") {
                        self.homepageViewModel.logout()
                    }

                    Button("About") {
                        self.homepageSheetViewModel.updateState(sheet: .about,
                                                                state: true)
                    }
                } label: {
                    VStack {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // If the user navigates away from the app, then
            // returns later while it is still in memory, we
            // want to refresh the data automatically
            Task.detached {
                await self.homepageViewModel.refreshData()
            }
        }
    }
}

struct LoggedInContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedInContentView(objectGraph: MockObjectGraph())
            .previewInterfaceOrientation(.portrait)
    }
}
