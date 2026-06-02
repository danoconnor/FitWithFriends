//
//  CompetitionOverviewView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import Combine
import SwiftUI

struct CompetitionOverviewView: View {
    private let showAllDetails: Bool
    private let objectGraph: IObjectGraph

    private let competitionOverview: CompetitionOverview
    private let homepageSheetViewModel: HomepageSheetViewModel
    @StateObject private var viewModel: CompetitionOverviewViewModel

    @State private var actionInProgress = false

    init(objectGraph: IObjectGraph, competitionOverview: CompetitionOverview, homepageSheetViewModel: HomepageSheetViewModel, showAllDetails: Bool) {
        self.objectGraph = objectGraph
        self.competitionOverview = competitionOverview
        self.homepageSheetViewModel = homepageSheetViewModel
        self.showAllDetails = showAllDetails
        _viewModel = StateObject(wrappedValue: CompetitionOverviewViewModel(authenticationManager: objectGraph.authenticationManager,
                                                                            competitionManager: objectGraph.competitionManager,
                                                                            competitionOverview: competitionOverview,
                                                                            serverEnrivonmentManager: objectGraph.serverEnvironmentManager,
                                                                            showAllDetails: showAllDetails))
    }

    var body: some View {
        Group {
            if showAllDetails {
                detailCard
            } else {
                homeCard
            }
        }
        .sheet(isPresented: $viewModel.shouldShowSheet, content: {
            if let shareUrl = viewModel.shareUrl {
                ShareSheet(url: shareUrl)
            }
        })
        .alert("Are you sure?", isPresented: $viewModel.shouldShowAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                Task.detached {
                    await self.viewModel.deleteCompetitionConfirmed()
                }
            }
        } message: {
            Text("This will permanently delete the competition for all users.")
        }
    }

    // MARK: - Home card (compact, rank-as-hero)

    private var homeCard: some View {
        Button {
            homepageSheetViewModel.updateState(sheet: .competitionDetails,
                                               state: true,
                                               contextData: competitionOverview)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                // Header: chips + menu
                HStack(spacing: 8) {
                    visibilityChip
                    scoringChip
                    Spacer()
                    menuButton
                }

                // Competition name (serif)
                Text(viewModel.competitionName)
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundStyle(Color("Ink"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                // Rank-as-hero row + today delta
                HStack(alignment: .firstTextBaseline) {
                    rankBlock
                    Spacer()
                    todayDeltaBlock
                }

                // Status line: leader + days left
                HStack(spacing: 8) {
                    if let leader = viewModel.leaderStatus {
                        FWFAvatar(name: leader.name, size: 22)
                        Text("**\(leader.name)** \(leader.relation)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color("InkSoft"))
                            .lineLimit(1)
                    } else if viewModel.userRank == 1 {
                        Text("You're in the lead 🏆")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color("Brand"))
                    } else {
                        Text(viewModel.userPositionDescription)
                            .font(.system(size: 13))
                            .foregroundStyle(Color("InkSoft"))
                    }

                    Spacer(minLength: 8)

                    if viewModel.daysLeft > 0 {
                        Text("\(viewModel.daysLeft)d left")
                            .font(.system(size: 11, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(viewModel.daysLeft <= 2 ? Color("Move") : Color("InkMute"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(
                                    viewModel.daysLeft <= 2 ? Color("MoveSoft") : Color("SurfaceAlt")
                                )
                            )
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detail card (showAllDetails == true)
    // Used inside CompetitionDetailView. Keeps the leaderboard list — the detail
    // screen itself layers a hero + standing card above this.

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                visibilityChip
                scoringChip
                Spacer()
                menuButton
            }

            Text(viewModel.competitionName)
                .font(.system(size: 22, weight: .regular, design: .serif))
                .foregroundStyle(Color("Ink"))

            HStack {
                Text(viewModel.userPositionDescription)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("Brand"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color("BrandSoft")))

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "calendar").font(.caption)
                    Text(viewModel.competitionDatesDescription).font(.caption)
                }
                .foregroundStyle(Color("InkMute"))
            }

            Divider().background(Color("Border"))

            // Scoring rule blurb
            VStack(alignment: .leading, spacing: 4) {
                Text("Scoring")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("InkMute"))
                Text(competitionOverview.scoringRules.humanReadableDescription)
                    .font(.caption)
                    .foregroundStyle(Color("InkSoft"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)

            Divider().background(Color("Border"))

            // Leaderboard
            VStack(spacing: 6) {
                ForEach(0 ..< viewModel.results.count, id: \.self) { position in
                    let result = viewModel.results[position]
                    NavigationLink {
                        UserCompetitionDailyDetailsView(
                            competitionId: competitionOverview.competitionId,
                            userId: result.userCompetitionPoints.userId,
                            userName: result.userCompetitionPoints.displayName,
                            objectGraph: objectGraph)
                    } label: {
                        UserCompetitionResultView(result: result,
                                                  isCompetitionActive: viewModel.isCompetitionActive,
                                                  scoringUnit: competitionOverview.scoringUnit)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        let availableActions = self.viewModel.getUserContextMenuActions(for: result.userCompetitionPoints.userId)
                        ForEach(availableActions, id: \.self) { action in
                            Button(action.description) {
                                Task.detached { await self.viewModel.performAction(action) }
                            }
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("competitionLeaderboard")
        }
    }

    // MARK: - Building blocks

    private var visibilityChip: some View {
        HStack(spacing: 4) {
            Image(systemName: competitionOverview.isPublic ? "globe" : "lock.fill")
                .font(.system(size: 10, weight: .semibold))
            Text(competitionOverview.isPublic ? "Public" : "Private")
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
        }
        .foregroundStyle(competitionOverview.isPublic ? Color("Brand") : Color("InkMute"))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(competitionOverview.isPublic ? Color("BrandSoft") : Color("SurfaceAlt"))
        )
    }

    private var scoringChip: some View {
        HStack(spacing: 4) {
            Image(systemName: viewModel.scoringRuleChipIcon)
                .font(.system(size: 10, weight: .semibold))
            Text(viewModel.scoringRuleChipLabel)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
        }
        .foregroundStyle(viewModel.scoringRuleChipColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(viewModel.scoringRuleChipColor.opacity(0.12))
        )
    }

    private var menuButton: some View {
        Menu {
            ForEach(viewModel.availableActions.sorted(), id: \.self) { action in
                Button(action.description) {
                    self.actionInProgress = true
                    Task.detached {
                        await self.viewModel.performAction(action)
                        await MainActor.run { self.actionInProgress = false }
                    }
                }
                .disabled(actionInProgress)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color("InkSoft"))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color("SurfaceAlt")))
        }
    }

    @ViewBuilder
    private var rankBlock: some View {
        if let ordinal = viewModel.userRankOrdinal, viewModel.totalParticipants > 0 {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(ordinal)
                    .font(.system(size: 40, weight: .bold))
                    .monospacedDigit()
                    .tracking(-0.02 * 40)
                    .foregroundStyle(viewModel.medalColor ?? Color("Ink"))
                Text("of \(viewModel.totalParticipants)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("InkMute"))
            }
        } else {
            Text(viewModel.userPositionDescription)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color("InkSoft"))
        }
    }

    @ViewBuilder
    private var todayDeltaBlock: some View {
        if let delta = viewModel.todayDelta {
            VStack(alignment: .trailing, spacing: 2) {
                Text(delta.value)
                    .font(.system(size: 22, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(delta.color)
                Text(delta.unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color("InkMute"))
            }
        }
    }
}

// MARK: - Compact completed row (collapsed "Completed" drawer)

/// Condensed resting-state row for a finished competition. Drops the live rank
/// hero + today delta and shows the user's final placement. Used inside the
/// home-feed "Completed" drawer (Option C).
struct CompletedCompetitionRow: View {
    let competitionOverview: CompetitionOverview
    let loggedInUserId: String?
    let onTap: () -> Void

    private var placement: Int? {
        competitionOverview.finalPlacement(for: loggedInUserId)
    }

    private var participantCount: Int {
        competitionOverview.currentResults.count
    }

    private var won: Bool {
        placement == 1
    }

    private var medalColor: Color? {
        MedalPalette.color(for: placement)
    }

    private var ordinalText: String {
        guard let placement else { return "—" }
        return CompetitionOverviewViewModel.ordinal(placement)
    }

    private var subtitle: String {
        let ended = "Ended \(MedalPalette.shortMonthDay(competitionOverview.endDate))"
        guard let placement else { return ended }
        let placeText = placement == 1 ? "You won" : "\(CompetitionOverviewViewModel.ordinal(placement)) of \(participantCount)"
        return "\(placeText) · \(ended)"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Leading placement medallion
                ZStack {
                    Circle().fill(medalColor?.opacity(0.18) ?? Color("SurfaceAlt"))
                    Text(ordinalText)
                        .font(.system(size: 15, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(medalColor ?? Color("InkSoft"))
                }
                .frame(width: 40, height: 40)

                // Name + subtitle
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

                if won {
                    Text("🏆")
                        .font(.system(size: 18))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color("InkFaint"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("completedCompetitionRow")
    }
}

// MARK: - Medal palette helpers

/// Shared medal-color + date helpers used across the completed-competition
/// treatments (compact row, result card, mini podium).
enum MedalPalette {
    /// Gold / Silver / Bronze for placements 1–3, `nil` otherwise.
    static func color(for placement: Int?) -> Color? {
        switch placement {
        case 1: return Color("Gold")
        case 2: return Color("Silver")
        case 3: return Color("Bronze")
        default: return nil
        }
    }

    static func shortMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct CompetitionOverviewView_Previews: PreviewProvider {
    private static var competitionOverview: CompetitionOverview {
        let results = [
            UserCompetitionPoints(userId: "user_0", firstName: "Alice",  lastName: "Chen",  total: 480, today: 110),
            UserCompetitionPoints(userId: "user_1", firstName: "Marcus", lastName: "Lee",   total: 365, today: 125),
            UserCompetitionPoints(userId: "user_2", firstName: "You",    lastName: "",      total: 422, today: 235),
            UserCompetitionPoints(userId: "user_3", firstName: "Sam",    lastName: "Smith", total: 100, today: 0),
        ]

        return CompetitionOverview(
            start: Date().addingTimeInterval(-.xtDays(8)),
            end: Date().addingTimeInterval(.xtDays(4)),
            currentResults: results)
    }

    static var previews: some View {
        CompetitionOverviewView(objectGraph: MockObjectGraph(),
                                competitionOverview: competitionOverview,
                                homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(), healthKitManager: MockHealthKitManager()),
                                showAllDetails: false)
            .fwfCard()
            .padding(.horizontal, 16)
            .background(Color("Bg"))

        CompetitionOverviewView(objectGraph: MockObjectGraph(),
                                competitionOverview: competitionOverview,
                                homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(), healthKitManager: MockHealthKitManager()),
                                showAllDetails: true)
            .fwfCard()
            .padding(.horizontal, 16)
            .background(Color("Bg"))

        VStack(spacing: 0) {
            CompletedCompetitionRow(
                competitionOverview: CompetitionOverview(
                    name: "Spring Step Showdown",
                    start: Date().addingTimeInterval(-.xtDays(14)),
                    end: Date().addingTimeInterval(-.xtDays(1)),
                    currentResults: [
                        UserCompetitionPoints(userId: "me", firstName: "You", lastName: "", total: 900, today: 0),
                        UserCompetitionPoints(userId: "a", firstName: "Alice", lastName: "Chen", total: 700, today: 0),
                    ]),
                loggedInUserId: "me",
                onTap: {})
            Divider()
            CompletedCompetitionRow(
                competitionOverview: CompetitionOverview(
                    name: "April Ring Rumble",
                    start: Date().addingTimeInterval(-.xtDays(14)),
                    end: Date().addingTimeInterval(-.xtDays(2)),
                    currentResults: [
                        UserCompetitionPoints(userId: "a", firstName: "Alice", lastName: "Chen", total: 700, today: 0),
                        UserCompetitionPoints(userId: "b", firstName: "Bob", lastName: "Lee", total: 650, today: 0),
                        UserCompetitionPoints(userId: "c", firstName: "Cara", lastName: "Ng", total: 600, today: 0),
                        UserCompetitionPoints(userId: "me", firstName: "You", lastName: "", total: 400, today: 0),
                    ]),
                loggedInUserId: "me",
                onTap: {})
        }
        .background(Color("Surface"))
        .padding(.horizontal, 16)
        .background(Color("Bg"))
        .previewDisplayName("Completed rows")
    }
}
