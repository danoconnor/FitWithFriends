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

    @Environment(\.dismiss) private var dismiss
    @State private var actionInProgress = false
    @State private var shouldShowShareSheet = false
    @State private var shareUrl: URL?

    init(competitionOverview: CompetitionOverview,
         homepageSheetViewModel: HomepageSheetViewModel,
         objectGraph: IObjectGraph) {
        self.competitionOverview = competitionOverview
        self.homepageSheetViewModel = homepageSheetViewModel
        self.objectGraph = objectGraph
        viewModel = CompetitionDetailViewModel(competitionManager: objectGraph.competitionManager,
                                               homepageSheetViewModel: homepageSheetViewModel)
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color("Bg").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 56)  // room for floating chrome

                        CompetitionDetailHeaderView(competitionOverview: competitionOverview)
                            .padding(.horizontal, 20)

                        CompetitionStandingCard(competitionOverview: competitionOverview,
                                                loggedInUserId: objectGraph.authenticationManager.loggedInUserId)
                            .padding(.horizontal, 16)

                        // Leaderboard
                        VStack(spacing: 10) {
                            ForEach(Array(sortedResults.enumerated()), id: \.offset) { index, points in
                                let position = UserPosition(userCompetitionPoints: points, position: UInt(index + 1))
                                let isCurrentUser = points.userId == objectGraph.authenticationManager.loggedInUserId

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

                        Spacer().frame(height: 24)
                    }
                }

                floatingChrome
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            .navigationBarHidden(true)
            .presentationDragIndicator(.visible)
            .sheet(isPresented: $shouldShowShareSheet) {
                if let shareUrl {
                    ShareSheet(url: shareUrl)
                }
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

    private var scoringChipLabel: String {
        CompetitionOverviewViewModel.scoringChip(for: competitionOverview.scoringRules).label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Visibility chip
            HStack(spacing: 4) {
                Image(systemName: competitionOverview.isPublic ? "globe" : "lock.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text(competitionOverview.isPublic ? "Public" : "Private")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(0.6)
                Text("·")
                Text("\(competitionOverview.currentResults.count) friends")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(0.6)
            }
            .foregroundStyle(competitionOverview.isPublic ? Color("Brand") : Color("InkMute"))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(competitionOverview.isPublic ? Color("BrandSoft") : Color("SurfaceAlt"))
            )

            // Competition name (editorial serif)
            Text(competitionOverview.competitionName)
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundStyle(Color("Ink"))
                .tracking(-0.02 * 32)
                .lineSpacing(-32 * 0.05)
                .fixedSize(horizontal: false, vertical: true)

            // Meta row — date range · scoring rule · days left
            HStack(spacing: 8) {
                Text(dateRangeText)
                    .font(.system(size: 13))
                    .foregroundStyle(Color("InkSoft"))
                metaDot
                Text(scoringChipLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(Color("InkSoft"))
                if daysLeft > 0 {
                    metaDot
                    Text("\(daysLeft) days left")
                        .font(.system(size: 13, weight: daysLeft <= 7 ? .semibold : .regular))
                        .foregroundStyle(daysLeft <= 7 ? Color("Brand") : Color("InkSoft"))
                }
            }
        }
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

    static var previews: some View {
        CompetitionDetailView(
            competitionOverview: overview,
            homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(), healthKitManager: MockHealthKitManager()),
            objectGraph: MockObjectGraph()
        )
    }
}
