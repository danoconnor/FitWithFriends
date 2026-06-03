//
//  PublicCompetitionDetailView.swift
//  FitWithFriends
//
//  Preview of a public competition the user has not joined yet. Loads the
//  competition's scoring rules and live leaderboard from the public (non-member)
//  overview endpoint so the user can size up a competition before deciding to
//  join. The leaderboard rows are read-only here — drilling into a specific
//  user's daily details requires membership.
//

import SwiftUI

struct PublicCompetitionDetailView: View {
    let competition: PublicCompetition
    let isUserPro: Bool
    let homepageSheetViewModel: HomepageSheetViewModel
    let objectGraph: IObjectGraph

    @Environment(\.dismiss) private var dismiss

    @State private var overview: CompetitionOverview?
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var showScoringRules = false
    @State private var joinInProgress = false

    private var loggedInUserId: String? {
        objectGraph.authenticationManager.loggedInUserId
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color("Bg").ignoresSafeArea()

                ScrollView {
                    Text("publicCompetitionDetailScreen")
                        .frame(width: 0, height: 0)
                        .opacity(0.001)
                        .accessibilityIdentifier("publicCompetitionDetailScreen")

                    VStack(spacing: 16) {
                        Spacer().frame(height: 56)  // room for floating back button

                        if let overview {
                            CompetitionDetailHeaderView(competitionOverview: overview,
                                                        isCompleted: overview.bucket == .completed,
                                                        onShowScoringRules: { showScoringRules = true })
                                .padding(.horizontal, 20)

                            leaderboard(overview)
                                .padding(.horizontal, 16)
                        } else if isLoading {
                            ProgressView("Loading competition…")
                                .padding(.top, 80)
                        } else {
                            loadErrorState
                                .padding(.horizontal, 20)
                                .padding(.top, 40)
                        }

                        Spacer().frame(height: 120)  // room for floating join CTA
                    }
                }

                floatingBack
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            .safeAreaInset(edge: .bottom) {
                joinCtaBar
            }
            .navigationBarHidden(true)
            .presentationDragIndicator(.visible)
            .task { await load() }
            .sheet(isPresented: $showScoringRules) {
                if let overview {
                    ScoringRulesSheet(competitionOverview: overview)
                }
            }
        }
    }

    // MARK: - Leaderboard

    @ViewBuilder
    private func leaderboard(_ overview: CompetitionOverview) -> some View {
        let sortedResults = overview.currentResults.sorted()

        VStack(spacing: 10) {
            HStack {
                Text(overview.bucket == .completed ? "Final standings" : "Leaderboard")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color("Ink"))
                Spacer()
            }
            .padding(.horizontal, 4)

            if sortedResults.isEmpty {
                Text("No one has joined yet — be the first!")
                    .font(.subheadline)
                    .foregroundStyle(Color("InkSoft"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .fwfCard()
            } else {
                ForEach(Array(sortedResults.enumerated()), id: \.offset) { index, points in
                    let position = UserPosition(userCompetitionPoints: points, position: UInt(index + 1))
                    UserCompetitionResultView(
                        result: position,
                        isCompetitionActive: overview.isCompetitionActive,
                        scoringUnit: overview.scoringUnit,
                        isCurrentUser: points.userId == loggedInUserId
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("publicCompetitionLeaderboard")
    }

    private var loadErrorState: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 32))
                .foregroundStyle(Color("InkMute"))
            Text(competition.displayName)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Color("Ink"))
                .multilineTextAlignment(.center)
            Text("We couldn't load this competition's details. Check your connection and try again.")
                .font(.subheadline)
                .foregroundStyle(Color("InkSoft"))
                .multilineTextAlignment(.center)
            FWFSecondaryButton("Try again", icon: "arrow.clockwise") {
                Task { await load() }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .fwfCard()
    }

    // MARK: - Floating chrome

    private var floatingBack: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color("Ink"))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color("Surface")))
                    .shadow(color: Color("Ink").opacity(0.10), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Join CTA

    @ViewBuilder
    private var joinCtaBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color("Border"))

            Group {
                if competition.isUserMember {
                    Label("You've joined", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("Brand"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                } else if isUserPro {
                    FWFPrimaryButton(joinInProgress ? "Joining…" : "Join Competition") {
                        join()
                    }
                    .disabled(joinInProgress)
                    .accessibilityIdentifier("publicCompetitionJoinButton")
                } else {
                    FWFPrimaryButton("Upgrade to Pro", icon: "star.fill") {
                        dismiss()
                        homepageSheetViewModel.updateState(sheet: .proUpgrade, state: true)
                    }
                    .accessibilityIdentifier("publicCompetitionUpgradeButton")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color("Bg"))
        }
    }

    // MARK: - Actions

    private func load() async {
        await MainActor.run {
            isLoading = true
            loadFailed = false
        }
        do {
            let result = try await objectGraph.competitionManager.getPublicCompetitionOverview(competitionId: competition.competitionId)
            await MainActor.run {
                self.overview = result
                self.isLoading = false
            }
        } catch {
            Logger.traceError(message: "Failed to load public competition overview for \(competition.competitionId)", error: error)
            await MainActor.run {
                self.loadFailed = true
                self.isLoading = false
            }
        }
    }

    private func join() {
        joinInProgress = true
        Task {
            do {
                try await objectGraph.competitionManager.joinPublicCompetition(competitionId: competition.competitionId)
                await MainActor.run {
                    joinInProgress = false
                    dismiss()
                }
            } catch {
                Logger.traceError(message: "Failed to join public competition \(competition.competitionId)", error: error)
                await MainActor.run { joinInProgress = false }
            }
        }
    }
}

struct PublicCompetitionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PublicCompetitionDetailView(
            competition: PublicCompetition(competitionId: UUID(),
                                           displayName: "City Step Showdown",
                                           startDate: Date(),
                                           endDate: Date().addingTimeInterval(7 * 86_400),
                                           memberCount: 12,
                                           isUserMember: false),
            isUserPro: true,
            homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(),
                                                           healthKitManager: MockHealthKitManager()),
            objectGraph: MockObjectGraph()
        )
    }
}
