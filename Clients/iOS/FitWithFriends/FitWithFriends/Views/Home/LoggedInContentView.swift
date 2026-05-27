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

    @StateObject private var homepageSheetViewModel: HomepageSheetViewModel
    @StateObject private var homepageViewModel: HomepageViewModel
    @StateObject private var competitionEndAlertViewModel: CompetitionEndAlertViewModel

    init(objectGraph: IObjectGraph) {
        self.objectGraph = objectGraph
        _homepageSheetViewModel = StateObject(wrappedValue: HomepageSheetViewModel(appProtocolHandler: objectGraph.appProtocolHandler,
                                                                                   healthKitManager: objectGraph.healthKitManager))
        _homepageViewModel = StateObject(wrappedValue: HomepageViewModel(authenticationManager: objectGraph.authenticationManager,
                                                                         competitionManager: objectGraph.competitionManager,
                                                                         healthKitManager: objectGraph.healthKitManager,
                                                                         subscriptionManager: objectGraph.subscriptionManager,
                                                                         userService: objectGraph.userService))
        _competitionEndAlertViewModel = StateObject(wrappedValue: CompetitionEndAlertViewModel(
            competitionManager: objectGraph.competitionManager,
            authenticationManager: objectGraph.authenticationManager
        ))
    }

    var body: some View {
        ZStack {
            Color("Bg").ignoresSafeArea()

            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        // Greeting + settings gear (replaces the navy toolbar)
                        greetingRow

                        // Today's activity
                        if let activitySummary = homepageViewModel.todayActivitySummary {
                            TodaySummaryView(
                                activitySummary: activitySummary,
                                headline: homepageViewModel.todayRingsHeadline,
                                stripItems: homepageViewModel.todayActivityStrip
                            )
                            .fwfCard()
                            .padding(.horizontal, 16)
                        } else if homepageViewModel.loadedActivitySummary {
                            healthDataMissing
                        }

                        // Public competitions section
                        if let publicCompetitions = homepageViewModel.publicCompetitions, !publicCompetitions.isEmpty {
                            sectionHeader("Public Competitions")

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
                            sectionHeader("Your Competitions")

                            ForEach(competitions) { competitionOverview in
                                CompetitionOverviewView(objectGraph: objectGraph,
                                                        competitionOverview: competitionOverview,
                                                        homepageSheetViewModel: homepageSheetViewModel,
                                                        showAllDetails: false)
                                    .fwfCard()
                                    .padding(.horizontal, 16)
                            }
                        } else if homepageViewModel.currentCompetitions != nil {
                            noCompetitionsEmptyState
                        }

                        // Start a new competition (dashed-outline secondary)
                        FWFSecondaryButton("Start a new competition", icon: "plus") {
                            homepageSheetViewModel.updateState(sheet: .createCompetition, state: true)
                        }
                        .accessibilityIdentifier("createCompetitionButton")
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
                        case .userDetails:
                            if let context = homepageSheetViewModel.sheetContextData as? UserDetailsSheetContext {
                                NavigationView {
                                    UserCompetitionDailyDetailsView(
                                        competitionId: context.competitionId,
                                        userId: context.userId,
                                        userName: context.userName,
                                        objectGraph: objectGraph)
                                }
                                .presentationDragIndicator(.visible)
                            } else {
                                Text("Error showing user details")
                            }
                        case .settings:
                            SettingsView(emailUtility: objectGraph.emailUtility,
                                         serverEnvironmentManager: objectGraph.serverEnvironmentManager,
                                         subscriptionManager: objectGraph.subscriptionManager,
                                         onDeleteAccount: { return await homepageViewModel.deleteAccount() })
                        case .proUpgrade:
                            ProUpgradeView(homepageSheetViewModel: homepageSheetViewModel,
                                           subscriptionManager: objectGraph.subscriptionManager,
                                           serverEnvironmentManager: objectGraph.serverEnvironmentManager)
                        default:
                            Text("Unknown sheet type: \(homepageSheetViewModel.sheetToShow.rawValue)")
                        }
                    })
                }
                .scrollContentBackground(.hidden)
                .background(Color("Bg"))
                .refreshable {
                    await homepageViewModel.refreshData()
                }
                .toolbarBackground(.hidden, for: .navigationBar)
                .navigationBarHidden(true)
            }
            .navigationViewStyle(.stack)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                guard ProcessInfo.processInfo.environment["FWF_UI_TESTING"] != "1" else { return }
                Task.detached {
                    await self.homepageViewModel.refreshData()
                }
            }

            if competitionEndAlertViewModel.shouldShowConfetti {
                ConfettiOverlayView()
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { competitionEndAlertViewModel.currentEndCompetition != nil },
                set: { if !$0 { competitionEndAlertViewModel.dismissCurrent() } }
            )
        ) {
            CompetitionEndView(
                viewModel: competitionEndAlertViewModel,
                homepageSheetViewModel: homepageSheetViewModel
            )
        }
    }

    // MARK: - Subviews

    private var greetingRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(homepageViewModel.greetingSubtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("InkMute"))

                Text(homepageViewModel.greetingTitle)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color("Ink"))
            }

            Spacer()

            Menu {
                Button("Logout") {
                    self.homepageViewModel.logout()
                }
                .accessibilityIdentifier("LogoutMenuButton")

                Button("Settings") {
                    self.homepageSheetViewModel.updateState(sheet: .settings, state: true)
                }
                .accessibilityIdentifier("SettingsMenuButton")
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color("Ink"))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color("Surface")))
                    .overlay(Circle().strokeBorder(Color("Border"), lineWidth: 1))
            }
            .accessibilityIdentifier("SettingsMenu")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("homeScreen")
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 19, weight: .semibold))
                .tracking(-0.02 * 19)
                .foregroundStyle(Color("Ink"))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private var healthDataMissing: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 32))
                .foregroundStyle(Color("InkMute"))

            Text("We're having trouble reading your activity information. Please check permissions in iOS Settings > Privacy > Health > Fit w/ Friends.")
                .font(.subheadline)
                .foregroundStyle(Color("InkSoft"))
                .multilineTextAlignment(.center)
        }
        .fwfCard()
        .padding(.horizontal, 16)
    }

    private var noCompetitionsEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy")
                .font(.system(size: 48))
                .foregroundStyle(Color("InkMute"))

            Text("No competitions yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color("Ink"))

            Text("Create a competition and invite your friends to get started!")
                .font(.subheadline)
                .foregroundStyle(Color("InkSoft"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .fwfCard()
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct LoggedInContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedInContentView(objectGraph: MockObjectGraph())
            .previewInterfaceOrientation(.portrait)
    }
}
