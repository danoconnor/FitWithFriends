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

    // Option C drawer expansion — collapsed by default, persisted per session.
    @State private var upcomingExpanded = false
    @State private var completedExpanded = false

    // Set when the user taps rematch on the competition-end cover; consumed in the
    // cover's onDismiss to open the create wizard after the cover finishes dismissing.
    @State private var shouldShowCreateAfterEnd = false

    // Same handoff for the completed-competition detail sheet's rematch CTA — consumed
    // in the detail sheet's onDismiss.
    @State private var shouldShowCreateAfterDetail = false

    // Set when the user taps "Full standings" on the competition-end sheet; the captured
    // competition is opened in the detail sheet from the end sheet's onDismiss (presenting
    // it while the sheet animates out gets dropped by SwiftUI).
    @State private var standingsCompetitionAfterEnd: CompetitionOverview?

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
                                    },
                                    onSelect: {
                                        homepageSheetViewModel.updateState(sheet: .publicCompetitionDetails,
                                                                           state: true,
                                                                           contextData: competition)
                                    }
                                )
                                .fwfCard()
                                .padding(.horizontal, 16)
                            }
                        }

                        // Competitions section (Option C — focus + drawers)
                        if homepageViewModel.isLoadingCompetitions {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .fwfCard()
                                .padding(.horizontal, 16)
                        } else if let competitions = homepageViewModel.currentCompetitions, !competitions.isEmpty {
                            competitionGroups(competitions)
                        } else {
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
                        // Open the create wizard only once the detail sheet has fully
                        // dismissed — presenting it while the sheet animates out gets
                        // dropped by SwiftUI.
                        if shouldShowCreateAfterDetail {
                            shouldShowCreateAfterDetail = false
                            homepageSheetViewModel.updateState(sheet: .createCompetition, state: true)
                        }
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
                                                      objectGraph: objectGraph,
                                                      onRematch: { shouldShowCreateAfterDetail = true })
                            } else {
                                Text("Error showing competition details")
                            }
                        case .publicCompetitionDetails:
                            if let publicCompetition = homepageSheetViewModel.sheetContextData as? PublicCompetition {
                                PublicCompetitionDetailView(competition: publicCompetition,
                                                            isUserPro: homepageViewModel.isUserPro,
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
                                         displayName: homepageViewModel.displayName,
                                         memberSinceLabel: homepageViewModel.memberSinceLabel,
                                         onDeleteAccount: { return await homepageViewModel.deleteAccount() },
                                         onSignOut: { homepageViewModel.logout() })
                        case .proUpgrade:
                            ProUpgradeView(subscriptionManager: objectGraph.subscriptionManager,
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
        .sheet(
            isPresented: Binding(
                get: { competitionEndAlertViewModel.currentEndCompetition != nil },
                set: { if !$0 { competitionEndAlertViewModel.dismissCurrent() } }
            ),
            onDismiss: {
                // Open the follow-on sheet only once the end sheet has fully dismissed —
                // presenting it while the sheet animates out gets dropped by SwiftUI.
                if shouldShowCreateAfterEnd {
                    shouldShowCreateAfterEnd = false
                    homepageSheetViewModel.updateState(sheet: .createCompetition, state: true)
                } else if let competition = standingsCompetitionAfterEnd {
                    standingsCompetitionAfterEnd = nil
                    homepageSheetViewModel.updateState(sheet: .competitionDetails,
                                                       state: true,
                                                       contextData: competition)
                }
            }
        ) {
            CompetitionEndView(
                viewModel: competitionEndAlertViewModel,
                onRematch: { shouldShowCreateAfterEnd = true },
                onViewStandings: { competition in standingsCompetitionAfterEnd = competition }
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
    private func sectionHeader(_ title: String, count: Int? = nil) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 19, weight: .semibold))
                .tracking(-0.02 * 19)
                .foregroundStyle(Color("Ink"))
            if let count {
                Text("\(count)")
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color("InkFaint"))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    // MARK: - Competition groups (Active / Upcoming / Completed)

    @ViewBuilder
    private func competitionGroups(_ competitions: [CompetitionOverview]) -> some View {
        let active = competitions.filter { $0.bucket == .active }
        let upcoming = competitions.filter { $0.bucket == .upcoming }
        let completed = competitions.filter { $0.bucket == .completed }
        let loggedInUserId = objectGraph.authenticationManager.loggedInUserId

        if !active.isEmpty {
            sectionHeader("Active now", count: active.count)

            ForEach(active) { competitionOverview in
                CompetitionOverviewView(objectGraph: objectGraph,
                                        competitionOverview: competitionOverview,
                                        homepageSheetViewModel: homepageSheetViewModel,
                                        showAllDetails: false)
                    .fwfCard()
                    .padding(.horizontal, 16)
            }
        }

        if !upcoming.isEmpty {
            CompetitionGroupDrawer(title: "Upcoming",
                                   icon: "calendar",
                                   accent: Color("Sun"),
                                   data: upcoming,
                                   isExpanded: $upcomingExpanded) { competitionOverview in
                UpcomingCompetitionRow(competitionOverview: competitionOverview) {
                    homepageSheetViewModel.updateState(sheet: .competitionDetails,
                                                       state: true,
                                                       contextData: competitionOverview)
                }
            }
            .padding(.horizontal, 16)
        }

        if !completed.isEmpty {
            CompetitionGroupDrawer(title: "Completed",
                                   icon: "trophy",
                                   accent: Color("Gold"),
                                   data: completed,
                                   isExpanded: $completedExpanded) { competitionOverview in
                CompletedCompetitionRow(competitionOverview: competitionOverview,
                                        loggedInUserId: loggedInUserId) {
                    homepageSheetViewModel.updateState(sheet: .competitionDetails,
                                                       state: true,
                                                       contextData: competitionOverview)
                }
            }
            .padding(.horizontal, 16)
        }
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

// MARK: - Competition group drawer (Option C)

/// Collapsible "drawer" section used for the Upcoming and Completed competition
/// groups. Collapsed by default; the header toggles expansion with a spring.
struct CompetitionGroupDrawer<Data: RandomAccessCollection, RowContent: View>: View where Data.Element: Identifiable {
    let title: String
    let icon: String
    let accent: Color
    let data: Data
    @Binding var isExpanded: Bool
    @ViewBuilder let row: (Data.Element) -> RowContent

    @Environment(\.colorScheme) private var colorScheme

    private var count: Int { data.count }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.4)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accent)
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(accent.opacity(0.16))
                        )

                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color("Ink"))

                    Spacer()

                    Text("\(count)")
                        .font(.system(size: 13, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(Color("InkMute"))

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color("InkFaint"))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("competitionDrawer_\(title)")

            if isExpanded {
                hairline
                ForEach(Array(data.enumerated()), id: \.element.id) { index, element in
                    row(element)
                    if index < count - 1 {
                        hairline
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color("Surface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color("Border"), lineWidth: colorScheme == .dark ? 1 : 0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.0 : 0.06), radius: 24, x: 0, y: 8)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.0 : 0.04), radius: 2, x: 0, y: 1)
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color("Border"))
            .frame(height: 1)
    }
}

// MARK: - Upcoming competition row (collapsed "Upcoming" drawer)

/// Lightweight resting-state row for a competition that hasn't started yet.
struct UpcomingCompetitionRow: View {
    let competitionOverview: CompetitionOverview
    let onTap: () -> Void

    private var startsInDays: Int {
        let seconds = competitionOverview.startDate.timeIntervalSince(Date())
        return max(0, Int(ceil(seconds / 86_400)))
    }

    private var subtitle: String {
        let startLabel = MedalPalette.shortMonthDay(competitionOverview.startDate)
        if startsInDays <= 0 {
            return "Starting today · \(startLabel)"
        }
        return "Starts in \(startsInDays)d · \(startLabel)"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color("Sun").opacity(0.16))
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color("Sun"))
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(competitionOverview.competitionName)
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundStyle(Color("Ink"))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color("InkMute"))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color("InkFaint"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("upcomingCompetitionRow")
    }
}

struct LoggedInContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedInContentView(objectGraph: MockObjectGraph())
            .previewInterfaceOrientation(.portrait)
    }
}
