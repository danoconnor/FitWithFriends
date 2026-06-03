//
//  CompetitionDetailView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/5/22.
//

import SwiftUI

struct CompetitionDetailView: View {
    private let competitionOverview: CompetitionOverview
    private let homepageSheetViewModel: HomepageSheetViewModel
    private let objectGraph: IObjectGraph
    private let viewModel: CompetitionDetailViewModel
    /// Invoked when the user taps the rematch CTA on a completed competition. The parent
    /// opens the create wizard from this sheet's onDismiss — presenting it here, while the
    /// sheet is still animating out, gets dropped by SwiftUI.
    private let onRematch: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var actionInProgress = false
    @State private var shouldShowShareSheet = false
    @State private var shareUrl: URL?
    @State private var showScoringRules = false

    @StateObject private var recapViewModel: CompetitionRecapViewModel

    init(competitionOverview: CompetitionOverview,
         homepageSheetViewModel: HomepageSheetViewModel,
         objectGraph: IObjectGraph,
         onRematch: @escaping () -> Void = {}) {
        self.competitionOverview = competitionOverview
        self.homepageSheetViewModel = homepageSheetViewModel
        self.objectGraph = objectGraph
        self.onRematch = onRematch
        viewModel = CompetitionDetailViewModel(competitionManager: objectGraph.competitionManager,
                                               homepageSheetViewModel: homepageSheetViewModel)
        _recapViewModel = StateObject(wrappedValue: CompetitionRecapViewModel(competitionManager: objectGraph.competitionManager))
    }

    private var isCompleted: Bool {
        competitionOverview.bucket == .completed
    }

    private var loggedInUserId: String? {
        objectGraph.authenticationManager.loggedInUserId
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color("Bg").ignoresSafeArea()

                ScrollView {
                    // Hidden accessibility marker so UI tests can confirm the detail
                    // sheet finished presenting (the redesigned floating chrome doesn't
                    // use a native navigation bar title we could match against).
                    Text("competitionDetailScreen")
                        .frame(width: 0, height: 0)
                        .opacity(0.001)
                        .accessibilityIdentifier("competitionDetailScreen")
                    VStack(spacing: 16) {
                        Spacer().frame(height: 56)  // room for floating chrome

                        CompetitionDetailHeaderView(competitionOverview: competitionOverview,
                                                    isCompleted: isCompleted,
                                                    onShowScoringRules: { showScoringRules = true })
                            .padding(.horizontal, 20)

                        if isCompleted {
                            CompetitionResultCard(competitionOverview: competitionOverview,
                                                  loggedInUserId: loggedInUserId)
                                .padding(.horizontal, 16)

                            CompetitionRecapGrid(scoringRules: competitionOverview.scoringRules,
                                                 scoringUnit: competitionOverview.scoringUnit,
                                                 stats: recapViewModel.stats)
                                .padding(.horizontal, 16)
                        } else {
                            CompetitionStandingCard(competitionOverview: competitionOverview,
                                                    loggedInUserId: loggedInUserId)
                                .padding(.horizontal, 16)
                        }

                        // Leaderboard
                        VStack(spacing: 10) {
                            if isCompleted {
                                HStack {
                                    Text("Final standings")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(Color("Ink"))
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                            }

                            ForEach(Array(sortedResults.enumerated()), id: \.offset) { index, points in
                                let position = UserPosition(userCompetitionPoints: points, position: UInt(index + 1))
                                let isCurrentUser = points.userId == loggedInUserId

                                NavigationLink {
                                    UserCompetitionDailyDetailsView(
                                        competitionId: competitionOverview.competitionId,
                                        userId: points.userId,
                                        userName: points.displayName,
                                        objectGraph: objectGraph)
                                } label: {
                                    UserCompetitionResultView(
                                        result: position,
                                        isCompetitionActive: competitionOverview.isCompetitionActive,
                                        scoringUnit: competitionOverview.scoringUnit,
                                        isCurrentUser: isCurrentUser
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("competitionLeaderboard")

                        if isCompleted {
                            completedCtaStack
                                .padding(.horizontal, 16)
                                .padding(.top, 4)
                        }

                        Spacer().frame(height: 24)
                    }
                }

                floatingChrome
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            .navigationBarHidden(true)
            .presentationDragIndicator(.visible)
            .task {
                guard isCompleted else { return }
                let finalTotal = competitionOverview.currentResults
                    .first(where: { $0.userId == loggedInUserId })?.totalPoints ?? 0
                await recapViewModel.loadIfNeeded(competitionId: competitionOverview.competitionId,
                                                  userId: loggedInUserId,
                                                  finalTotal: finalTotal)
            }
            .sheet(isPresented: $shouldShowShareSheet) {
                if let shareUrl {
                    ShareSheet(url: shareUrl)
                }
            }
            .sheet(isPresented: $showScoringRules) {
                ScoringRulesSheet(competitionOverview: competitionOverview)
            }
        }
    }

    // MARK: - Completed CTA stack

    private var didWin: Bool {
        competitionOverview.finalPlacement(for: loggedInUserId) == 1
    }

    private var completedCtaStack: some View {
        VStack(spacing: 10) {
            FWFPrimaryButton(didWin ? "Defend your title" : "Demand a rematch", icon: "trophy") {
                // Signal the parent to open the create wizard from this sheet's onDismiss,
                // then dismiss. Opening it here races the dismissal animation and SwiftUI
                // silently drops the presentation. Mirrors CompetitionEndView.
                onRematch()
                dismiss()
            }
            .accessibilityIdentifier("competitionDetailRematchButton")

            FWFSecondaryButton(didWin ? "Share your win" : "Share recap", icon: "square.and.arrow.up") {
                shareCompetition()
            }
        }
    }

    // MARK: - Helpers

    private var sortedResults: [UserCompetitionPoints] {
        competitionOverview.currentResults.sorted()
    }

    // MARK: - Floating chrome

    private var floatingChrome: some View {
        HStack {
            chromeButton(systemName: "chevron.left") { dismiss() }
            Spacer()
            if competitionOverview.isUserAdmin {
                chromeButton(systemName: "square.and.arrow.up") {
                    shareCompetition()
                }
            }
            actionMenuButton
        }
    }

    private func chromeButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color("Ink"))
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color("Surface")))
                .shadow(color: Color("Ink").opacity(0.10), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var actionMenuButton: some View {
        if competitionOverview.isUserAdmin {
            Menu {
                Button("Delete competition", role: .destructive) {
                    Task.detached {
                        try? await self.objectGraph.competitionManager.deleteCompetition(competitionId: competitionOverview.competitionId)
                        await self.objectGraph.competitionManager.refreshCompetitionOverviews()
                        await MainActor.run { dismiss() }
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color("Ink"))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color("Surface")))
                    .shadow(color: Color("Ink").opacity(0.10), radius: 8, x: 0, y: 2)
            }
        } else {
            Menu {
                Button("Leave competition", role: .destructive) {
                    Task.detached {
                        try? await self.objectGraph.competitionManager.leaveCompetition(competitionId: competitionOverview.competitionId)
                        await self.objectGraph.competitionManager.refreshCompetitionOverviews()
                        await MainActor.run { dismiss() }
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color("Ink"))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color("Surface")))
                    .shadow(color: Color("Ink").opacity(0.10), radius: 8, x: 0, y: 2)
            }
        }
    }

    private func shareCompetition() {
        Task.detached {
            do {
                let adminDetail = try await objectGraph.competitionManager.getCompetitionAdminDetail(for: competitionOverview.competitionId)
                let url = JoinCompetitionProtocolData.createWebsiteUrl(
                    serverBaseUrl: objectGraph.serverEnvironmentManager.baseUrl,
                    competitionId: adminDetail.competitionId,
                    competitionToken: adminDetail.competitionAccessToken
                )
                await MainActor.run {
                    self.shareUrl = url
                    self.shouldShowShareSheet = true
                }
            } catch {
                Logger.traceError(message: "Failed to get admin details for \(competitionOverview.competitionId)", error: error)
            }
        }
    }
}

// MARK: - Competition Detail Header

struct CompetitionDetailHeaderView: View {
    let competitionOverview: CompetitionOverview
    /// When `true`, the meta row shows an "Ended {date}" badge instead of "N days left".
    var isCompleted: Bool = false
    /// Invoked when the user taps the scoring chip or the ? help button.
    var onShowScoringRules: (() -> Void)? = nil

    private var daysLeft: Int {
        let seconds = competitionOverview.endDate.timeIntervalSince(Date())
        return max(0, Int(ceil(seconds / 86_400)))
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: competitionOverview.startDate)
        let end = formatter.string(from: competitionOverview.endDate)
        return "\(start) → \(end)"
    }

    private var scoringChip: CompetitionOverviewViewModel.ScoringChip {
        CompetitionOverviewViewModel.scoringChip(for: competitionOverview.scoringRules)
    }

    private var memberNoun: String {
        competitionOverview.isPublic ? "members" : "friends"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chips row — visibility + tappable scoring chip
            HStack(spacing: 8) {
                visibilityChip
                Button {
                    onShowScoringRules?()
                } label: {
                    scoringChipView
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("scoringChip")
                .disabled(onShowScoringRules == nil)
            }

            // Name + ? help button
            HStack(alignment: .top, spacing: 8) {
                Text(competitionOverview.competitionName)
                    .font(.system(size: 31, weight: .regular, design: .serif))
                    .foregroundStyle(Color("Ink"))
                    .tracking(-0.02 * 31)
                    .lineSpacing(-31 * 0.05)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if onShowScoringRules != nil {
                    Button {
                        onShowScoringRules?()
                    } label: {
                        Image(systemName: "questionmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color("Brand"))
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color("BrandSoft")))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("How scoring works")
                    .accessibilityIdentifier("scoringRulesButton")
                    .padding(.top, 4)
                }
            }

            // Meta row — date range · scoring rule · (days left | Ended date)
            HStack(spacing: 8) {
                Text(dateRangeText)
                    .font(.system(size: 13))
                    .foregroundStyle(Color("InkSoft"))
                metaDot
                Text(scoringChip.label)
                    .font(.system(size: 13))
                    .foregroundStyle(Color("InkSoft"))
                if isCompleted {
                    metaDot
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color("InkFaint"))
                        Text("Ended \(MedalPalette.shortMonthDay(competitionOverview.endDate))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color("InkMute"))
                    }
                } else if daysLeft > 0 {
                    metaDot
                    Text("\(daysLeft) days left")
                        .font(.system(size: 13, weight: daysLeft <= 7 ? .semibold : .regular))
                        .foregroundStyle(daysLeft <= 7 ? Color("Brand") : Color("InkSoft"))
                }
            }
        }
    }

    private var visibilityChip: some View {
        HStack(spacing: 4) {
            Image(systemName: competitionOverview.isPublic ? "globe" : "lock.fill")
                .font(.system(size: 10, weight: .semibold))
            Text(competitionOverview.isPublic ? "Public" : "Private")
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
            Text("·")
            Text("\(competitionOverview.currentResults.count) \(memberNoun)")
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
        }
        .foregroundStyle(competitionOverview.isPublic ? Color("Brand") : Color("InkMute"))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(competitionOverview.isPublic ? Color("BrandSoft") : Color("SurfaceAlt"))
        )
    }

    private var scoringChipView: some View {
        HStack(spacing: 4) {
            Image(systemName: scoringChip.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(scoringChip.label)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
        }
        .foregroundStyle(scoringChip.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(scoringChip.color.opacity(0.12)))
    }

    private var metaDot: some View {
        Circle()
            .fill(Color("InkFaint"))
            .frame(width: 3, height: 3)
    }
}

// MARK: - Standing card

struct CompetitionStandingCard: View {
    let competitionOverview: CompetitionOverview
    let loggedInUserId: String?

    private var sortedResults: [UserCompetitionPoints] {
        competitionOverview.currentResults.sorted()
    }

    private var userPositionIndex: Int? {
        guard let loggedInUserId else { return nil }
        return sortedResults.firstIndex { $0.userId == loggedInUserId }
    }

    private var userPosition: Int? {
        userPositionIndex.map { $0 + 1 }
    }

    private var medalColor: Color {
        guard let pos = userPosition else { return Color("Ink") }
        switch pos {
        case 1: return Color("Gold")
        case 2: return Color("Silver")
        case 3: return Color("Bronze")
        default: return Color("Ink")
        }
    }

    /// "390 pts behind 2nd · 244 pts ahead of 4th"
    private var diffSubtitle: String {
        guard let idx = userPositionIndex,
              let mePts = sortedResults[idx].totalPoints else {
            return ""
        }
        var fragments: [String] = []
        if idx > 0 {
            if let abovePts = sortedResults[idx - 1].totalPoints {
                let gap = abovePts - mePts
                let formatted = ScoringValueFormatter.format(abs(gap), unit: competitionOverview.scoringUnit)
                fragments.append("\(formatted) behind \(CompetitionOverviewViewModel.ordinal(idx))")
            }
        }
        if idx + 1 < sortedResults.count {
            if let belowPts = sortedResults[idx + 1].totalPoints {
                let lead = mePts - belowPts
                let formatted = ScoringValueFormatter.format(abs(lead), unit: competitionOverview.scoringUnit)
                fragments.append("\(formatted) ahead of \(CompetitionOverviewViewModel.ordinal(idx + 2))")
            }
        }
        return fragments.joined(separator: " · ")
    }

    /// 0..1 across the lifetime of the competition.
    private var timeProgress: Double {
        let total = competitionOverview.endDate.timeIntervalSince(competitionOverview.startDate)
        guard total > 0 else { return 1 }
        let elapsed = Date().timeIntervalSince(competitionOverview.startDate)
        return min(1.0, max(0.0, elapsed / total))
    }

    private var totalDays: Int {
        let total = competitionOverview.endDate.timeIntervalSince(competitionOverview.startDate)
        return max(1, Int(ceil(total / 86_400)))
    }

    private var dayOf: Int {
        let elapsed = Date().timeIntervalSince(competitionOverview.startDate)
        return max(1, min(totalDays, Int(ceil(elapsed / 86_400))))
    }

    private var daysLeft: Int {
        max(0, totalDays - dayOf + 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your standing")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color("InkMute"))

                    if let pos = userPosition {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(CompetitionOverviewViewModel.ordinal(pos))
                                .font(.system(size: 36, weight: .bold))
                                .monospacedDigit()
                                .tracking(-0.02 * 36)
                                .foregroundStyle(medalColor)
                            Text("of \(sortedResults.count)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color("InkMute"))
                        }
                    } else {
                        Text("—")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(Color("InkFaint"))
                    }

                    if !diffSubtitle.isEmpty {
                        Text(diffSubtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Color("InkSoft"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Time left")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color("InkMute"))
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(daysLeft)")
                            .font(.system(size: 32, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(Color("Ink"))
                        Text("days")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color("InkMute"))
                    }
                }
            }

            // Time progress bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color("BrandSoft"))
                            .frame(height: 6)
                        Capsule()
                            .fill(LinearGradient(colors: [Color("Brand"), Color("BrandHi")],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * timeProgress, height: 6)
                    }
                }
                .frame(height: 6)

                Text("Day \(dayOf) of \(totalDays) · \(Int(timeProgress * 100))% of the way done")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color("InkMute"))
            }
        }
        .fwfCard(padding: 18)
    }
}

// MARK: - Mini podium

/// Three-step podium rendered in 2-1-3 order. The current user's step gets a
/// medal-colored ring around the avatar. Missing placements render a neutral
/// step with a blank avatar well.
struct MiniPodium: View {
    struct Entry {
        let rank: Int
        let name: String
        let isCurrentUser: Bool
    }

    /// Entries for whatever placements are present (ranks 1...3).
    let entries: [Entry]
    var scale: CGFloat = 1

    private func entry(forRank rank: Int) -> Entry? {
        entries.first { $0.rank == rank }
    }

    private func stepHeight(_ rank: Int) -> CGFloat {
        switch rank {
        case 1: return 46 * scale
        case 2: return 34 * scale
        default: return 26 * scale
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            step(rank: 2)
            step(rank: 1)
            step(rank: 3)
        }
    }

    @ViewBuilder
    private func step(rank: Int) -> some View {
        let medal = MedalPalette.color(for: rank) ?? Color("InkFaint")
        let avatarSize = 26 * scale

        VStack(spacing: 6) {
            if let e = entry(forRank: rank) {
                FWFAvatar(name: e.name, size: avatarSize, ring: e.isCurrentUser ? medal : nil)
            } else {
                Circle()
                    .fill(Color("SurfaceAlt"))
                    .frame(width: avatarSize, height: avatarSize)
            }

            ZStack(alignment: .top) {
                UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 0,
                                       bottomTrailingRadius: 0, topTrailingRadius: 8,
                                       style: .continuous)
                    .fill(medal.opacity(0.9))
                Text("\(rank)")
                    .font(.system(size: 15 * scale, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.top, 5)
            }
            .frame(width: 54 * scale, height: stepHeight(rank))
        }
        .frame(width: 54 * scale)
    }
}

// MARK: - Final result card (completed competition)

/// Replaces the live `CompetitionStandingCard` once a competition has ended.
/// Shows the user's final placement, the winner / champion treatment, and a podium.
struct CompetitionResultCard: View {
    let competitionOverview: CompetitionOverview
    let loggedInUserId: String?

    private var sortedResults: [UserCompetitionPoints] {
        competitionOverview.currentResults.sorted()
    }

    private var placement: Int? {
        competitionOverview.finalPlacement(for: loggedInUserId)
    }

    private var won: Bool { placement == 1 }

    private var medalColor: Color? {
        MedalPalette.color(for: placement)
    }

    private var participantCount: Int { sortedResults.count }

    private var finalTotalText: String? {
        guard let row = sortedResults.first(where: { $0.userId == loggedInUserId }),
              let total = row.totalPoints else { return nil }
        return ScoringValueFormatter.format(total, unit: competitionOverview.scoringUnit)
    }

    private var winner: UserCompetitionPoints? {
        sortedResults.first
    }

    private var podiumEntries: [MiniPodium.Entry] {
        sortedResults.prefix(3).enumerated().map { index, points in
            MiniPodium.Entry(rank: index + 1,
                             name: points.displayName,
                             isCurrentUser: points.userId == loggedInUserId)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your final result")
                        .font(.system(size: 10.5, weight: .semibold))
                        .tracking(1.0)
                        .textCase(.uppercase)
                        .foregroundStyle(Color("InkMute"))

                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(placement.map { CompetitionOverviewViewModel.ordinal($0) } ?? "—")
                            .font(.system(size: 44, weight: .bold))
                            .monospacedDigit()
                            .tracking(-0.02 * 44)
                            .foregroundStyle(medalColor ?? Color("Ink"))
                        Text("of \(participantCount)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color("InkMute"))
                    }

                    if let finalTotalText {
                        Text("Final total **\(finalTotalText)**")
                            .font(.system(size: 13))
                            .foregroundStyle(Color("InkSoft"))
                    }
                }

                Spacer()

                if won {
                    VStack(spacing: 2) {
                        Text("🏆").font(.system(size: 40))
                        Text("CHAMPION")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.9)
                            .foregroundStyle(Color("Gold"))
                    }
                } else if let winner {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("WINNER")
                            .font(.system(size: 10.5, weight: .semibold))
                            .tracking(1.0)
                            .foregroundStyle(Color("InkMute"))
                        HStack(spacing: 7) {
                            FWFAvatar(name: winner.displayName, size: 28, ring: Color("Gold"))
                            Text(winner.firstName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color("Ink"))
                        }
                    }
                }
            }

            Divider().background(Color("Border"))

            MiniPodium(entries: podiumEntries, scale: 1.04)
                .frame(maxWidth: .infinity)
        }
        .fwfCard(padding: 18)
        .overlay(
            // Tint the surface ~9% toward gold when the user won.
            Group {
                if won {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color("Gold").opacity(0.09))
                        .allowsHitTesting(false)
                }
            }
        )
    }
}

// MARK: - Recap stats

/// Pure, testable summary of a user's per-day performance across a competition.
/// Derived from the same daily-summary data the end-of-competition screen uses.
struct CompetitionRecapStats: Equatable {
    let totalDays: Int
    let fullRingDays: Int
    let bestMoveStreak: Int
    let activeDays: Int
    let bestActiveStreak: Int
    let bestDayValue: Double
    let bestDayDate: Date?
    let finalTotal: Double

    static func compute(summaries: [DailySummary], finalTotal: Double) -> CompetitionRecapStats {
        let chronological = summaries.sorted { $0.date < $1.date }

        var fullRingDays = 0
        var bestMoveStreak = 0
        var currentMoveStreak = 0
        var activeDays = 0
        var bestActiveStreak = 0
        var currentActiveStreak = 0

        for summary in chronological {
            // Full-ring day
            if closedAllRings(summary) { fullRingDays += 1 }

            // Move-ring streak
            if summary.caloriesGoal > 0 && summary.caloriesBurned >= summary.caloriesGoal {
                currentMoveStreak += 1
                bestMoveStreak = max(bestMoveStreak, currentMoveStreak)
            } else {
                currentMoveStreak = 0
            }

            // Active-day streak (any scored activity)
            if summary.points > 0 {
                activeDays += 1
                currentActiveStreak += 1
                bestActiveStreak = max(bestActiveStreak, currentActiveStreak)
            } else {
                currentActiveStreak = 0
            }
        }

        let best = chronological.max { $0.points < $1.points }

        return CompetitionRecapStats(
            totalDays: chronological.count,
            fullRingDays: fullRingDays,
            bestMoveStreak: bestMoveStreak,
            activeDays: activeDays,
            bestActiveStreak: bestActiveStreak,
            bestDayValue: best?.points ?? 0,
            bestDayDate: best?.date,
            finalTotal: finalTotal
        )
    }

    private static func closedAllRings(_ summary: DailySummary) -> Bool {
        guard summary.caloriesGoal > 0 else { return false }
        let move = summary.caloriesBurned >= summary.caloriesGoal
        let exercise = summary.exerciseTimeGoal == 0 || summary.exerciseTime >= summary.exerciseTimeGoal
        let stand = summary.standTimeGoal == 0 || summary.standTime >= summary.standTimeGoal
        return move && exercise && stand
    }
}

/// Loads the logged-in user's daily summaries for a completed competition and
/// derives the recap stats. No new endpoint — reuses `getUserCompetitionDetails`.
@MainActor
final class CompetitionRecapViewModel: ObservableObject {
    @Published private(set) var stats: CompetitionRecapStats?

    private let competitionManager: ICompetitionManager
    private var hasLoaded = false

    init(competitionManager: ICompetitionManager) {
        self.competitionManager = competitionManager
    }

    func loadIfNeeded(competitionId: UUID, userId: String?, finalTotal: Double) async {
        guard !hasLoaded, let userId else { return }
        hasLoaded = true
        do {
            let details = try await competitionManager.getUserCompetitionDetails(competitionId: competitionId, userId: userId)
            stats = CompetitionRecapStats.compute(summaries: details.dailySummaries, finalTotal: finalTotal)
        } catch {
            Logger.traceError(message: "Failed to load recap summaries for \(competitionId)", error: error)
        }
    }
}

// MARK: - Recap grid

/// 2×2 grid of recap stat cells. Labels are tailored to the competition's
/// scoring family so a steps/workouts comp doesn't show ring-centric copy.
struct CompetitionRecapGrid: View {
    let scoringRules: ScoringRules
    let scoringUnit: ScoringUnit
    let stats: CompetitionRecapStats?

    private struct Cell: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let label: String
        let value: String
    }

    private func plain(_ value: Int) -> String { "\(value)" }

    private var cells: [Cell] {
        let bestDay = stats.map { ScoringValueFormatter.formatCompact($0.bestDayValue, unit: scoringUnit) } ?? "—"
        let finalTotal = stats.map { ScoringValueFormatter.formatCompact($0.finalTotal, unit: scoringUnit) } ?? "—"

        switch scoringRules.kind {
        case .rings:
            return [
                Cell(icon: "checkmark.circle.fill", color: Color("Brand"),
                     label: "Full-ring days", value: stats.map { plain($0.fullRingDays) } ?? "—"),
                Cell(icon: "flame.fill", color: Color("Move"),
                     label: "Best Move streak", value: stats.map { plain($0.bestMoveStreak) } ?? "—"),
                Cell(icon: "arrow.up", color: Color("Exercise"),
                     label: "Best day", value: bestDay),
                Cell(icon: "trophy", color: Color("Sun"),
                     label: "Final total", value: finalTotal),
            ]
        case .workouts, .daily:
            return [
                Cell(icon: "checkmark.circle.fill", color: Color("Brand"),
                     label: "Active days", value: stats.map { plain($0.activeDays) } ?? "—"),
                Cell(icon: "flame.fill", color: Color("Move"),
                     label: "Best streak", value: stats.map { plain($0.bestActiveStreak) } ?? "—"),
                Cell(icon: "arrow.up", color: Color("Exercise"),
                     label: "Best day", value: bestDay),
                Cell(icon: "trophy", color: Color("Sun"),
                     label: "Final total", value: finalTotal),
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your competition recap")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color("Ink"))
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(cells) { cell in
                    recapCell(cell)
                }
            }
        }
    }

    private func recapCell(_ cell: Cell) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: cell.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(cell.color)
                Text(cell.label)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .textCase(.uppercase)
                    .foregroundStyle(Color("InkMute"))
            }
            Text(cell.value)
                .font(.system(size: 19, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Color("Ink"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color("Surface"))
        )
    }
}

// MARK: - Scoring rules sheet

/// "How scoring works" bottom sheet. Decodes the competition's `scoringRules`
/// into human-readable rule blocks plus a worked example. Opened from the
/// scoring chip and the ? button in the detail header.
struct ScoringRulesSheet: View {
    let competitionOverview: CompetitionOverview
    @Environment(\.dismiss) private var dismiss

    private var scoringChip: CompetitionOverviewViewModel.ScoringChip {
        CompetitionOverviewViewModel.scoringChip(for: competitionOverview.scoringRules)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                    .padding(.horizontal, 18)
                    .padding(.top, 24)

                Text(competitionOverview.scoringRules.humanReadableDescription)
                    .font(.system(size: 14))
                    .foregroundStyle(Color("InkSoft"))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 2)

                ruleBlocks
                    .padding(.horizontal, 18)
            }
            .padding(.bottom, 28)
        }
        .background(Color("Bg"))
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .accessibilityIdentifier("scoringRulesSheet")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                FWFTag(text: "How scoring works", color: Color("InkMute"))
                Text(competitionOverview.competitionName)
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .tracking(-0.02 * 24)
                    .foregroundStyle(Color("Ink"))
                    .fixedSize(horizontal: false, vertical: true)
                chip(text: scoringChip.label, icon: scoringChip.icon, color: scoringChip.color)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("InkSoft"))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color("SurfaceAlt")))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    @ViewBuilder
    private var ruleBlocks: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch competitionOverview.scoringRules {
            case let .rings(includedRings, minGoals, dailyCap):
                ringsBlocks(includedRings: includedRings, minGoals: minGoals, dailyCap: dailyCap)
            case let .daily(metric):
                dailyBlocks(metric: metric)
            case let .workouts(metric, activityTypes):
                workoutsBlocks(metric: metric, activityTypes: activityTypes)
            }
        }
    }

    // MARK: Rings

    @ViewBuilder
    private func ringsBlocks(includedRings: Set<ScoringRing>, minGoals: RingMinGoals?, dailyCap: Int?) -> some View {
        let ptsPerRing = 100
        let orderedIncluded = ScoringRing.allCases.filter { includedRings.contains($0) }
        let hasFloor = (minGoals?.isEmpty == false)

        RuleBlock(icon: "flame.fill", color: Color("Move"), title: "Rings that count",
                  trailing: AnyView(
                    Text("\(ptsPerRing) pts max / ring / day")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color("InkMute"))
                  )) {
            HStack(spacing: 10) {
                ForEach(ScoringRing.allCases, id: \.self) { ring in
                    ringCard(ring: ring, on: includedRings.contains(ring))
                }
            }
            Text("Each day you earn up to **\(ptsPerRing)** points per counted ring, scaled to how far you fill it. Closing a ring 100% banks the full \(ptsPerRing).")
                .font(.system(size: 12))
                .foregroundStyle(Color("InkSoft"))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }

        RuleBlock(icon: "gauge", color: Color("Brand"), title: "Minimum goal floor",
                  trailing: AnyView(chip(text: hasFloor ? "On" : "Off",
                                         color: hasFloor ? Color("Brand") : Color("InkMute")))) {
            if hasFloor, let minGoals {
                VStack(spacing: 0) {
                    let rows = floorRows(minGoals: minGoals, includedRings: includedRings)
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        SpecRow(label: row.label, value: row.value, isLast: index == rows.count - 1)
                    }
                }
                Text("Players whose personal Apple goals sit below the floor are scored as if their goal matched it — so a low goal can't be an easy win. Higher personal goals are used as-is.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color("InkSoft"))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No floor is enforced — everyone is scored against their own personal Apple goals.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color("InkSoft"))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        RuleBlock(icon: "clock", color: Color("Sun"), title: "Daily cap",
                  trailing: AnyView(chip(text: dailyCap.map { "\($0) pts" } ?? "Off",
                                         color: dailyCap != nil ? Color("Sun") : Color("InkMute")))) {
            if let dailyCap {
                Text("No matter how much you do, a single day can earn at most **\(dailyCap) points**. Keeps one monster session from deciding the competition — consistency wins.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color("InkSoft"))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("There's no cap — every point you earn in a day counts in full.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color("InkSoft"))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        ringsWorkedExample(orderedIncluded: orderedIncluded, ptsPerRing: ptsPerRing, dailyCap: dailyCap)
    }

    private func ringCard(ring: ScoringRing, on: Bool) -> some View {
        VStack(spacing: 8) {
            RuleRingGlyph(color: ringColor(ring), fraction: on ? 0.78 : 0.25)
                .frame(width: 40, height: 40)
                .opacity(on ? 1 : 0.55)
            Text(ring.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color("Ink"))
            if on {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(ringColor(ring))
            } else {
                Text("Not counted")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Color("InkFaint"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(on ? Color("SurfaceAlt") : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color("Border"), style: StrokeStyle(lineWidth: on ? 0 : 1, dash: [4, 3]))
        )
        .opacity(on ? 1 : 0.6)
    }

    private func floorRows(minGoals: RingMinGoals, includedRings: Set<ScoringRing>) -> [(label: String, value: String)] {
        var rows: [(String, String)] = []
        if includedRings.contains(.calories), let calories = minGoals.calories {
            rows.append(("Move floor", "\(calories) cal"))
        }
        if includedRings.contains(.exercise), let exercise = minGoals.exerciseTime {
            rows.append(("Exercise floor", "\(exercise) min"))
        }
        if includedRings.contains(.stand), let stand = minGoals.standTime {
            rows.append(("Stand floor", "\(stand) hr"))
        }
        return rows
    }

    private func ringsWorkedExample(orderedIncluded: [ScoringRing], ptsPerRing: Int, dailyCap: Int?) -> some View {
        var lines: [WorkedExample.Line] = orderedIncluded.map { ring in
            WorkedExample.Line(label: "Closed \(ring.displayName) ring (100%)", value: "\(ptsPerRing) pts")
        }
        let subtotal = ptsPerRing * max(orderedIncluded.count, 1)
        let resultValue: String
        if let dailyCap, dailyCap < subtotal {
            lines.append(WorkedExample.Line(label: "Day subtotal \(subtotal) — over the \(dailyCap) cap", value: "→ \(dailyCap)"))
            resultValue = "\(dailyCap) pts"
        } else {
            resultValue = "\(subtotal) pts"
        }
        return WorkedExample(lines: lines, resultLabel: "Points earned that day", resultValue: resultValue)
    }

    // MARK: Daily

    @ViewBuilder
    private func dailyBlocks(metric: DailyMetric) -> some View {
        let unit = competitionOverview.scoringUnit
        let metricLabel = metric == .steps ? "Steps" : "Walking + running distance"
        let countNoun = metric == .steps ? "step" : "meter"

        RuleBlock(icon: "shoeprints.fill", color: Color("Brand"), title: "What counts",
                  trailing: AnyView(chip(text: metricLabel, color: Color("Brand")))) {
            Text("Every \(countNoun) Apple Health records counts toward your total. There's no goal to clear — just rack up as much as you can over the competition.")
                .font(.system(size: 12))
                .foregroundStyle(Color("InkSoft"))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }

        RuleBlock(icon: "checkmark.circle.fill", color: Color("InkMute"), title: "No caps or floors") {
            VStack(spacing: 0) {
                SpecRow(label: "Daily cap", value: "Off", valueColor: Color("InkMute"),
                        sub: "Big days count in full.")
                SpecRow(label: "Minimum goal", value: "Off", valueColor: Color("InkMute"),
                        sub: "No threshold to clear.", isLast: true)
            }
        }

        WorkedExample(
            lines: [
                WorkedExample.Line(label: "A strong day", value: ScoringValueFormatter.formatCompact(9_300, unit: unit)),
                WorkedExample.Line(label: "A rest day", value: ScoringValueFormatter.formatCompact(2_000, unit: unit)),
                WorkedExample.Line(label: "…added up across every day", value: ""),
            ],
            resultLabel: "Highest total wins",
            resultValue: "Σ \(unitWord(unit))"
        )
    }

    // MARK: Workouts

    private func workoutMetricCopy(_ metric: WorkoutMetric) -> (label: String, perUnit: String) {
        switch metric {
        case .calories: return ("Calories", "calorie burned in")
        case .duration: return ("Minutes", "minute of")
        case .distance: return ("Distance", "meter covered in")
        }
    }

    @ViewBuilder
    private func workoutsBlocks(metric: WorkoutMetric, activityTypes: [UInt]?) -> some View {
        let metricLabel = workoutMetricCopy(metric).label
        let perUnit = workoutMetricCopy(metric).perUnit
        let typeNames = (activityTypes ?? []).compactMap { WorkoutActivityTypeCatalog.displayName(for: $0) }

        RuleBlock(icon: "dumbbell.fill", color: Color("Brand"), title: "What counts",
                  trailing: AnyView(chip(text: metricLabel, color: Color("Brand")))) {
            Text("You bank points for every \(perUnit) qualifying workouts. Only the workout types below count\(typeNames.isEmpty ? "" : ", and each has to be logged in Health").")
                .font(.system(size: 12))
                .foregroundStyle(Color("InkSoft"))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }

        if typeNames.isEmpty {
            RuleBlock(icon: "checkmark.circle.fill", color: Color("Exercise"), title: "Eligible workout types",
                      trailing: AnyView(chip(text: "All", color: Color("Exercise")))) {
                Text("Every workout type tracked in Health counts toward your score.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color("InkSoft"))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            RuleBlock(icon: "checkmark.circle.fill", color: Color("Exercise"), title: "Eligible workout types",
                      trailing: AnyView(
                        Text("\(typeNames.count) selected")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color("InkMute"))
                      )) {
                FlowLayout(spacing: 6) {
                    ForEach(typeNames, id: \.self) { name in
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                            Text(name)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color("Brand"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color("BrandSoft")))
                    }
                }
                Text("Other workout types are logged in Health but earn **0 points** here.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color("InkSoft"))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        workoutsWorkedExample(metric: metric, eligibleName: typeNames.first)
    }

    private func workoutsWorkedExample(metric: WorkoutMetric, eligibleName: String?) -> some View {
        let name = eligibleName ?? "Run"
        switch metric {
        case .duration:
            return WorkedExample(
                lines: [
                    WorkedExample.Line(label: "45-min \(name.lowercased()) (eligible)", value: "45 min"),
                    WorkedExample.Line(label: "30-min session (eligible)", value: "30 min"),
                    WorkedExample.Line(label: "An ineligible workout type", value: "0", zero: true),
                ],
                resultLabel: "Minutes banked that day",
                resultValue: "75 min"
            )
        case .calories:
            return WorkedExample(
                lines: [
                    WorkedExample.Line(label: "A hard \(name.lowercased()) (eligible)", value: "420 kcal"),
                    WorkedExample.Line(label: "An ineligible workout type", value: "0", zero: true),
                ],
                resultLabel: "Calories banked that day",
                resultValue: "420 kcal"
            )
        case .distance:
            return WorkedExample(
                lines: [
                    WorkedExample.Line(label: "A long \(name.lowercased()) (eligible)", value: "8 km"),
                    WorkedExample.Line(label: "An ineligible workout type", value: "0", zero: true),
                ],
                resultLabel: "Distance banked that day",
                resultValue: "8 km"
            )
        }
    }

    // MARK: Small helpers

    private func ringColor(_ ring: ScoringRing) -> Color {
        switch ring {
        case .calories: return Color("Move")
        case .exercise: return Color("Exercise")
        case .stand: return Color("Stand")
        }
    }

    private func unitWord(_ unit: ScoringUnit) -> String {
        switch unit {
        case .points: return "pts"
        case .steps: return "steps"
        case .kcal: return "kcal"
        case .minutes: return "min"
        case .meters: return "distance"
        }
    }

    private func chip(text: String, icon: String? = nil, color: Color) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.14)))
    }
}

// MARK: - Scoring rules sheet building blocks

private struct RuleBlock<Content: View>: View {
    let icon: String
    let color: Color
    let title: String
    var trailing: AnyView? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(color.opacity(0.15))
                    )
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color("Ink"))
                Spacer(minLength: 8)
                if let trailing {
                    trailing
                }
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color("Surface"))
        )
    }
}

private struct SpecRow: View {
    let label: String
    var value: String? = nil
    var valueColor: Color = Color("Ink")
    var sub: String? = nil
    var on: Bool = true
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: on ? .semibold : .medium))
                        .foregroundStyle(Color("Ink"))
                    if let sub {
                        Text(sub)
                            .font(.system(size: 12))
                            .foregroundStyle(Color("InkSoft"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                if let value {
                    Text(value)
                        .font(.system(size: 14, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(valueColor)
                }
            }
            .padding(.vertical, 10)
            .opacity(on ? 1 : 0.5)

            if !isLast {
                Rectangle()
                    .fill(Color("Border"))
                    .frame(height: 1)
            }
        }
    }
}

private struct WorkedExample: View {
    struct Line {
        let label: String
        let value: String
        var zero: Bool = false
    }

    let lines: [Line]
    let resultLabel: String
    let resultValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("Brand"))
                Text("WORKED EXAMPLE")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Color("Brand"))
            }

            VStack(spacing: 10) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(line.label)
                            .font(.system(size: 13))
                            .foregroundStyle(Color("InkSoft"))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        if !line.value.isEmpty {
                            Text(line.value)
                                .font(.system(size: 14, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(line.zero ? Color("InkMute") : Color("Ink"))
                        }
                    }
                }
            }

            Rectangle()
                .fill(Color("Brand").opacity(0.2))
                .frame(height: 1)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(resultLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color("Ink"))
                Spacer(minLength: 8)
                Text(resultValue)
                    .font(.system(size: 18, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color("Brand"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color("BrandSoft"))
        )
    }
}

/// Single activity-ring glyph used inside the rules sheet's "rings that count" cards.
private struct RuleRingGlyph: View {
    let color: Color
    let fraction: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.22), lineWidth: 5)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct CompetitionDetailView_Previews: PreviewProvider {
    private static var overview: CompetitionOverview {
        let results = [
            UserCompetitionPoints(userId: "u1", firstName: "Alice", lastName: "Chen",  total: 480, today: 110),
            UserCompetitionPoints(userId: "u2", firstName: "You",   lastName: "",      total: 422, today: 235),
            UserCompetitionPoints(userId: "u3", firstName: "Marcus", lastName: "Lee",  total: 365, today: 125),
        ]
        return CompetitionOverview(
            start: Date().addingTimeInterval(-.xtDays(8)),
            end: Date().addingTimeInterval(.xtDays(4)),
            currentResults: results
        )
    }

    private static func completedOverview(userTotal: Double, rules: ScoringRules = .default) -> CompetitionOverview {
        let results = [
            UserCompetitionPoints(userId: "u1", firstName: "Alice", lastName: "Chen",  total: 480, today: 0),
            UserCompetitionPoints(userId: "u2", firstName: "You",   lastName: "",      total: userTotal, today: 0),
            UserCompetitionPoints(userId: "u3", firstName: "Marcus", lastName: "Lee",  total: 365, today: 0),
            UserCompetitionPoints(userId: "u4", firstName: "Sam",   lastName: "Smith", total: 210, today: 0),
        ]
        return CompetitionOverview(
            start: Date().addingTimeInterval(-.xtDays(14)),
            end: Date().addingTimeInterval(-.xtDays(1)),
            currentResults: results,
            scoringRules: rules
        )
    }

    static var previews: some View {
        Group {
            CompetitionDetailView(
                competitionOverview: overview,
                homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(), healthKitManager: MockHealthKitManager()),
                objectGraph: MockObjectGraph()
            )
            .previewDisplayName("Active")

            CompetitionDetailView(
                competitionOverview: completedOverview(userTotal: 520),
                homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(), healthKitManager: MockHealthKitManager()),
                objectGraph: MockObjectGraph()
            )
            .previewDisplayName("Completed · Won")

            CompetitionDetailView(
                competitionOverview: completedOverview(userTotal: 365),
                homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(), healthKitManager: MockHealthKitManager()),
                objectGraph: MockObjectGraph()
            )
            .previewDisplayName("Completed · Off-podium")

            ScoringRulesSheet(competitionOverview: CompetitionOverview(
                name: "Step Showdown",
                scoringRules: .daily(metric: .steps)
            ))
            .previewDisplayName("Rules · Steps")

            ScoringRulesSheet(competitionOverview: CompetitionOverview(
                name: "Ring Rumble",
                scoringRules: .rings(includedRings: [.calories, .exercise], minGoals: RingMinGoals(calories: 500, exerciseTime: 30), dailyCap: 350)
            ))
            .previewDisplayName("Rules · Rings")

            ScoringRulesSheet(competitionOverview: CompetitionOverview(
                name: "Cardio Cup",
                scoringRules: .workouts(metric: .duration, activityTypes: [37, 52, 13])
            ))
            .previewDisplayName("Rules · Workouts")
        }
    }
}
