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

    @ObservedObject private var homepageSheetViewModel: HomepageSheetViewModel
    @ObservedObject private var homepageViewModel: HomepageViewModel

    init(objectGraph: IObjectGraph) {
        self.objectGraph = objectGraph
        homepageSheetViewModel = HomepageSheetViewModel(healthKitManager: objectGraph.healthKitManager)
        homepageViewModel = HomepageViewModel(competitionManager: objectGraph.competitionManager,
                                              healthKitManager: objectGraph.healthKitManager)
    }

    var body: some View {
        ScrollView {
            VStack {
                if let activitySummary = homepageViewModel.todayActivitySummary {
                    TodaySummaryView(activitySummary: activitySummary)
                        .cornerRadius(10)
                        .padding()
                }

                if let currentCompetition = homepageViewModel.currentCompetition {
                    CompetitionDetailView(objectGraph: objectGraph, competitionOverview: currentCompetition)
                        .cornerRadius(10)
                        .padding()
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
            .sheet(isPresented: $homepageSheetViewModel.shouldShowSheet, content: {
                switch homepageSheetViewModel.sheetToShow {
                case .createCompetition:
                    CreateCompetitionView(homepageSheetViewModel: homepageSheetViewModel, objectGraph: objectGraph)
                case .permissionPrompt:
                    PermissionPromptView(homepageSheetViewModel: homepageSheetViewModel, objectGraph: objectGraph)
                default:
                    Text("Unknown sheet type: \(homepageSheetViewModel.sheetToShow.rawValue)")
                }
            })
        }
    }
}

struct LoggedInContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedInContentView(objectGraph: MockObjectGraph())
    }
}
