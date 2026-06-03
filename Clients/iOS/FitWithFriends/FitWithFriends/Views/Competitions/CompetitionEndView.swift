//
//  CompetitionEndView.swift
//  FitWithFriends
//
//  Full-screen variant-aware celebration / consolation screen shown when a
//  competition ends. Replaces the legacy `.alert(...)`. Five variants:
//    1st (won) · 2nd (silver) · 3rd (bronze) · 4th–2nd-from-last (midPack) · last
//  The lower the finish, the more the screen shrinks the rank chrome and grows
//  personal stats.
//

import SwiftUI

struct CompetitionEndView: View {
    @ObservedObject var viewModel: CompetitionEndAlertViewModel
    /// Invoked when the user taps the rematch / new-competition CTA. The parent is
    /// responsible for opening the create wizard once this cover has fully dismissed —
    /// presenting it here (while the cover is still animating out) gets dropped by SwiftUI.
    var onRematch: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    @State private var showingShare: Bool = false

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    FWFTag(text: "Competition complete",
                           color: Color("Brand"),
                           background: Color("BrandSoft"))
                        .accessibilityIdentifier("competitionEndScreen")
                        .padding(.top, 24)

                    headline
                        .padding(.horizontal, 22)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)

                    subParagraph
                        .padding(.horizontal, 22)

                    hero
                        .padding(.horizontal, 16)

                    statsGrid
                        .padding(.horizontal, 16)

                    actionRow
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)
                }
                .frame(maxWidth: .infinity)
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        viewModel.dismissCurrent()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color("Ink"))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color("Surface")))
                            .shadow(color: Color("Ink").opacity(0.1), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("competitionEndDismiss")
                    .accessibilityLabel("OK")
                    .padding(16)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showingShare) {
            // Reuses the system share sheet with a simple plain-text composition.
            if let text = shareText, let url = URL(string: text) ?? URL(string: "https://example.com") {
                ShareSheet(url: url)
            }
        }
    }

    // MARK: - Variant text

    private var backgroundColor: Color {
        switch viewModel.endVariant {
        case .won:     return Color("Sun").opacity(0.18)
        case .silver:  return Color("Bg")
        case .bronze:  return Color("Bg")
        case .midPack: return Color("Sun").opacity(0.10)
        case .last:    return Color("Bg")
        }
    }

    @ViewBuilder
    private var headline: some View {
        switch viewModel.endVariant {
        case .won:
            FWFDisplay(parts: [("You ", false), ("won", true), (".", false)],
                       size: 56, italicColor: Color("Brand"), alignment: .center)
        case .silver:
            FWFDisplay(parts: [("So ", false), ("close.", true), (" Silver.", false)],
                       size: 48, italicColor: Color("Silver"), alignment: .center)
        case .bronze:
            FWFDisplay(parts: [("Bronze. ", false), ("The podium.", true)],
                       size: 48, italicColor: Color("Bronze"), alignment: .center)
        case .midPack:
            FWFDisplay(parts: [("You showed up. ", false), ("Every day.", true)],
                       size: 44, italicColor: Color("Sun"), alignment: .center)
        case .last:
            FWFDisplay(parts: [("Tough one. But you ", false), ("showed up", true), (".", false)],
                       size: 44, italicColor: Color("Brand"), alignment: .center)
        }
    }

    private var subParagraph: some View {
        let text: String
        switch viewModel.endVariant {
        case .won:
            text = "You closed all three rings on \(viewModel.daysClosedAllRings) of \(viewModel.dailySummaries.count) days — your most consistent comp yet."
        case .silver:
            if let gap = viewModel.gapToFirst, let winner = viewModel.winner {
                text = "\(gap) behind \(winner.firstName). She had a big day — without it, this was yours."
            } else {
                text = "An incredibly close finish."
            }
        case .bronze:
            text = "A solid \(viewModel.dailySummaries.count) days. You beat most of your group, closed all rings \(viewModel.daysClosedAllRings) days."
        case .midPack:
            text = "Your best streak yet — \(viewModel.moveRingStreak) consecutive Move closures. The leaderboard says one thing, the chart says you're getting fitter."
        case .last:
            text = "Not your week on the leaderboard. That said — here's everything you did right."
        }
        return Text(text)
            .font(.system(size: 15))
            .foregroundStyle(Color("InkSoft"))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Hero

    @ViewBuilder
    private var hero: some View {
        switch viewModel.endVariant {
        case .won:
            podium(highlightStep: 1)
        case .silver:
            silverHero
        case .bronze:
            podium(highlightStep: 3)
        case .midPack:
            streakHero
        case .last:
            achievementStrip
        }
    }

    private func podium(highlightStep: Int) -> some View {
        // 3-step podium with steps shown in medal colors. The user's avatar sits
        // on the highlighted step.
        let me = viewModel.currentEndCompetition?.currentResults
            .sorted()
            .first(where: { $0.userId == nil ? false : true })  // any row exists
        _ = me  // suppress unused warning for previews

        return HStack(alignment: .bottom, spacing: 8) {
            podiumStep(rank: 2, height: 70, color: Color("Silver"), isMine: highlightStep == 2)
            podiumStep(rank: 1, height: 96, color: Color("Gold"), isMine: highlightStep == 1)
            podiumStep(rank: 3, height: 50, color: Color("Bronze"), isMine: highlightStep == 3)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .fwfCard(padding: 0)
    }

    private func podiumStep(rank: Int, height: CGFloat, color: Color, isMine: Bool) -> some View {
        VStack(spacing: 6) {
            if isMine {
                FWFAvatar(name: "You", size: 36, ring: color)
            } else {
                Circle().fill(Color("InkFaint").opacity(0.4)).frame(width: 32, height: 32)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color.opacity(0.9))
                Text("\(rank)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 64, height: height)
        }
    }

    private var silverHero: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle().fill(Color("Silver"))
                Text("2")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 140, height: 140)

            if let winner = viewModel.winner {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Winner")
                        .font(.system(size: 10.5, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color("InkMute"))
                    FWFAvatar(name: winner.displayName, size: 36, ring: Color("Gold"))
                    Text(winner.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color("Ink"))
                    if let total = winner.totalPoints, let competition = viewModel.currentEndCompetition {
                        Text(ScoringValueFormatter.format(total, unit: competition.scoringUnit))
                            .font(.system(size: 12))
                            .foregroundStyle(Color("InkSoft"))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .fwfCard(padding: 0)
    }

    private var streakHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(viewModel.moveRingStreak)")
                    .font(.system(size: 64, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color("Sun"))
                Text("day Move streak")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("InkSoft"))
            }

            // 12-cell intensity strip
            let summaries = viewModel.dailySummaries.sorted { $0.date < $1.date }
            HStack(spacing: 3) {
                ForEach(Array(summaries.enumerated()), id: \.offset) { _, summary in
                    let closed = summary.caloriesGoal > 0 && summary.caloriesBurned >= summary.caloriesGoal
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(closed ? Color("Sun") : Color("Sun").opacity(0.18))
                        .frame(height: 18)
                }
            }

            Text("Consecutive days you closed your Move ring across this competition.")
                .font(.system(size: 11))
                .foregroundStyle(Color("InkMute"))
        }
        .fwfCard(padding: 18)
    }

    private var achievementStrip: some View {
        VStack(spacing: 10) {
            achievementCard(icon: "checkmark.seal.fill", color: Color("Brand"),
                            title: "Logged \(viewModel.dailySummaries.count) of \(viewModel.dailySummaries.count) days",
                            subtitle: "Perfect attendance — most participants miss 2+ days.")
            achievementCard(icon: "flame.fill", color: Color("Move"),
                            title: "Move ring closed \(viewModel.daysClosedAllRings) days",
                            subtitle: "Days you hit your Move goal during this competition.")
            if let best = viewModel.bestDay, let competition = viewModel.currentEndCompetition {
                achievementCard(icon: "arrow.up.right", color: Color("Exercise"),
                                title: "\(ScoringValueFormatter.format(best.points, unit: competition.scoringUnit)) on \(Self.shortMonthDay(best.date))",
                                subtitle: "Your highest-effort day in this competition.")
            }
        }
    }

    private static func shortMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func achievementCard(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(Circle().fill(color.opacity(0.18)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("Ink"))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color("InkSoft"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .fwfCard(padding: 12)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            statCell(label: "Total", value: viewModel.totalDisplay)
            statCell(label: "Full-ring days",
                     value: "\(viewModel.daysClosedAllRings) of \(viewModel.dailySummaries.count)")
            statCell(label: "Move streak",
                     value: "\(viewModel.moveRingStreak) days",
                     highlight: viewModel.endVariant == .midPack || viewModel.endVariant == .last)
            if let best = viewModel.bestDay, let competition = viewModel.currentEndCompetition {
                statCell(label: "Best day",
                         value: "\(ScoringValueFormatter.formatCompact(best.points, unit: competition.scoringUnit)) · \(Self.shortMonthDay(best.date))")
            } else {
                statCell(label: "Best day", value: "—")
            }
        }
    }

    private func statCell(label: String, value: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Color("InkMute"))
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(highlight ? Color("Sun") : Color("Ink"))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(highlight ? Color("Sun").opacity(0.14) : Color("Surface"))
        )
    }

    // MARK: - Actions

    private var actionRow: some View {
        VStack(spacing: 10) {
            // Primary CTA — "Demand a rematch" or "Rematch" depending on variant.
            FWFPrimaryButton(rematchCtaTitle) {
                // Signal the parent to open the create wizard from the cover's
                // onDismiss, then dismiss. Opening it here races the dismissal
                // animation and SwiftUI silently drops the presentation.
                onRematch()
                viewModel.dismissCurrent()
                dismiss()
            }
            .accessibilityIdentifier("competitionEndRematchButton")

            FWFSecondaryButton(shareCtaTitle, icon: "square.and.arrow.up") {
                showingShare = true
            }
        }
    }

    private var rematchCtaTitle: String {
        switch viewModel.endVariant {
        case .silver, .last: return "Demand a rematch"
        default: return "Start a new competition"
        }
    }

    private var shareCtaTitle: String {
        switch viewModel.endVariant {
        case .won:    return "Share win"
        case .midPack: return "Share streak"
        case .last:   return "Share progress"
        default:      return "Share"
        }
    }

    private var shareText: String? {
        guard let competition = viewModel.currentEndCompetition,
              let ordinal = viewModel.userPositionOrdinal else { return nil }
        return "I finished \(ordinal) in \(competition.competitionName) on FitWithFriends."
    }
}

struct CompetitionEndView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview-friendly fake — uses the back-compat init.
        CompetitionEndView(
            viewModel: CompetitionEndAlertViewModel(
                competitionManager: MockCompetitionManager(),
                authenticationManager: MockAuthenticationManager()
            )
        )
    }
}
