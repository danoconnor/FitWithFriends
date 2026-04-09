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
        homepageSheetViewModel = HomepageSheetViewModel(appProtocolHandler: objectGraph.appProtocolHandler,
                                                        healthKitManager: objectGraph.healthKitManager)
        homepageViewModel = HomepageViewModel(authenticationManager: objectGraph.authenticationManager,
                                              competitionManager: objectGraph.competitionManager,
                                              healthKitManager: objectGraph.healthKitManager,
                                              subscriptionManager: objectGraph.subscriptionManager)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // App title
                    HStack {
                        Text("Fit with Friends")
                            .font(.largeTitle.bold())
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    // Today's activity section
                    if let activitySummary = homepageViewModel.todayActivitySummary {
                        TodaySummaryView(activitySummary: activitySummary,
                                         homepageSheetViewModel: homepageSheetViewModel,
                                         objectGraph: objectGraph)
                            .fwfCard()
                            .padding(.horizontal, 16)
                    } else if homepageViewModel.loadedActivitySummary {
                        // Health data access issue
                        VStack(spacing: 12) {
                            Image(systemName: "heart.text.square")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)

                            Text("We're having trouble reading your activity information. Please check permissions in iOS Settings > Privacy > Health > Fit w/ Friends.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .fwfCard()
                        .padding(.horizontal, 16)
                    }

                    // Public competitions section
                    if let publicCompetitions = homepageViewModel.publicCompetitions, !publicCompetitions.isEmpty {
                        HStack {
                            Text("Public Competitions")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        ForEach(publicCompetitions) { competition in
                            PublicCompetitionCard(
                                competition: competition,
                                isUserPro: homepageViewModel.isUserPro,
                                onJoin: {
                                    Task {
                                        try? await objectGraph.competitionManager.joinPublicCompetition(competitionId: competition.competitionId)
                                    }
                                },
                                onUpgrade: {
                                    homepageSheetViewModel.updateState(sheet: .proUpgrade, state: true)
                                }
                            )
                            .fwfCard()
                            .padding(.horizontal, 16)
                        }
                    }

                    // Competitions section
                    if let competitions = homepageViewModel.currentCompetitions, !competitions.isEmpty {
                        HStack {
                            Text("Your Competitions")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        ForEach(competitions) { competitionOverview in
                            CompetitionOverviewView(objectGraph: objectGraph,
                                                    competitionOverview: competitionOverview,
                                                    homepageSheetViewModel: homepageSheetViewModel,
                                                    showAllDetails: false)
                                .fwfCard()
                                .padding(.horizontal, 16)
                        }
                    } else if homepageViewModel.currentCompetitions != nil {
                        // Empty state
                        VStack(spacing: 12) {
                            Image(systemName: "trophy")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)

                            Text("No competitions yet")
                                .font(.headline)

                            Text("Create a competition and invite your friends to get started!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .fwfCard()
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }

                    // Create competition button
                    FWFPrimaryButton("New Competition", icon: "plus.circle.fill") {
                        homepageSheetViewModel.updateState(sheet: .createCompetition, state: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
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
                    case .proUpgrade:
                        ProUpgradeView(homepageSheetViewModel: homepageSheetViewModel,
                                       subscriptionManager: objectGraph.subscriptionManager)
                    default:
                        Text("Unknown sheet type: \(homepageSheetViewModel.sheetToShow.rawValue)")
                    }
                })
            }
            .refreshable {
                await homepageViewModel.refreshData()
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color("FwFBrandingColor"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
                    Image(systemName: "gearshape.fill")
                        .font(.body)
                        .foregroundStyle(.white)
                }
                .accessibilityIdentifier("SettingsMenu")
            }
        }
        .navigationViewStyle(.stack)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            guard ProcessInfo.processInfo.environment["FWF_UI_TESTING"] != "1" else { return }
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
