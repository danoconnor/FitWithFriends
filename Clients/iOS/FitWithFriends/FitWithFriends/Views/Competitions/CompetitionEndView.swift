//
//  CompetitionEndView.swift
//  FitWithFriends
//
//  The "Competition Done" results sheet (design Direction B — "Podium"). Shown as a
//  bottom sheet over the home feed the moment a competition ends (or when the user
//  taps a finished competition). It names the competition that finished, celebrates a
//  win with a brand-gradient header + confetti, visualizes the top-3 podium, and
//  highlights the user's "You finished Nth of N" row. The same layout adapts to all
//  three outcomes — loud on a win, paper-calm and gracious on a mid/last finish.
//
//  Tapping "Share" renders a standalone result card (CompetitionShareCardView) to an
//  image via ImageRenderer and offers it — plus a hype sentence and the App Store link —
//  through the system share sheet.
//

import ConfettiSwiftUI
import SwiftUI

struct CompetitionEndView: View {
    @ObservedObject var viewModel: CompetitionEndAlertViewModel
    /// Invoked when the user taps the rematch CTA. The parent is responsible for opening the
    /// create wizard once this sheet has fully dismissed — presenting it here (while the sheet
    /// is still animating out) gets dropped by SwiftUI.
    var onRematch: () -> Void = {}
    /// Invoked when the user taps "Full standings" — the parent routes to the Competition
    /// Detail screen (which renders the full leaderboard) after this sheet dismisses.
    var onViewStandings: (CompetitionOverview) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale

    @State private var showingShare = false
    @State private var shareItems: [Any] = []
    @State private var confettiTrigger = 0

    private var won: Bool { viewModel.endOutcome == .won }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerCap
                bodyRegion
                    .padding(.top, -12)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color("Surface"))
        .presentationDetents([.height(580), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
        .sheet(isPresented: $showingShare) {
            ShareSheet(activityItems: shareItems)
        }
    }

    private func dismissSheet() {
        viewModel.dismissCurrent()
        dismiss()
    }

    // MARK: - Header cap

    private var headerCap: some View {
        VStack(alignment: .leading, spacing: 0) {
            grabHandle

            VStack(alignment: .leading, spacing: 9) {
                eyebrow
                headline
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.bottom, 30)
        .background(headerBackground)
        .overlay(alignment: .top) {
            if won {
                Color.clear
                    .frame(height: 1)
                    .confettiCannon(trigger: $confettiTrigger,
                                    num: 60,
                                    colors: confettiColors,
                                    openingAngle: .degrees(40),
                                    closingAngle: .degrees(140),
                                    radius: 220)
            }
        }
        .onAppear {
            guard won, !reduceMotion else { return }
            confettiTrigger += 1
        }
    }

    @ViewBuilder
    private var headerBackground: some View {
        if won {
            LinearGradient(colors: [Color("BrandHi"), Color("Brand")],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        } else {
            Color("SurfaceAlt")
        }
    }

    private var confettiColors: [Color] {
        [Color("Move"), Color("Exercise"), Color("Stand"), Color("Gold"), Color("BrandHi")]
    }

    private var grabHandle: some View {
        // Tap or drag-down dismisses. We draw the handle ourselves (system indicator is
        // hidden) so it can carry the win-mode white treatment from the design.
        Button(action: dismissSheet) {
            Capsule()
                .fill((won ? Color.white.opacity(0.6) : Color("InkFaint")).opacity(won ? 1 : 0.7))
                .frame(width: 38, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("competitionEndDismiss")
        .accessibilityLabel("Dismiss")
    }

    private var eyebrow: some View {
        HStack(spacing: 7) {
            if won {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text("Final results")
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(1.05)
                .textCase(.uppercase)
                .foregroundStyle(won ? Color.white.opacity(0.82) : Color("InkSoft"))
                .accessibilityIdentifier("competitionEndScreen")
        }
    }

    private var headline: some View {
        let name = viewModel.currentEndCompetition?.competitionName ?? ""
        let primary = won ? Color.white : Color("Ink")
        let accent = won ? Color.white.opacity(0.82) : Color("InkSoft")
        return (
            Text(name + "\n")
                .foregroundColor(primary)
            + Text(viewModel.headlineAccent)
                .italic()
                .foregroundColor(accent)
        )
        .font(.system(size: 27, weight: .regular, design: .serif))
        .tracking(-0.54)
        .lineSpacing(1)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Body region (white)

    private var bodyRegion: some View {
        VStack(spacing: 18) {
            CompetitionPodiumView(entries: viewModel.podiumEntries,
                                  scoringUnit: viewModel.currentEndCompetition?.scoringUnit ?? .points)
            CompetitionResultSummaryRow(placement: viewModel.userPlacement,
                                        title: youFinishedTitle,
                                        subline: viewModel.outcomeSubline,
                                        score: viewModel.userScoreValue,
                                        unitTag: viewModel.unitTagText)
            actions
        }
        .padding(.top, 20)
        .padding(.horizontal, 22)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20, style: .continuous)
                .fill(Color("Surface"))
        )
    }

    private var youFinishedTitle: String {
        guard viewModel.userPlacement != nil else { return "Competition complete" }
        return "You finished \(viewModel.userPositionOrdinal ?? "") of \(viewModel.memberCount)"
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 9) {
            // Rematch — restarts the same competition with the same people.
            Button {
                onRematch()
                dismissSheet()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Rematch")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(Color("BgDeep"))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color("Ink"))
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("competitionEndRematchButton")

            HStack(spacing: 9) {
                ghostButton(title: "Share", icon: "square.and.arrow.up", color: Color("Ink")) {
                    presentShare()
                }
                .accessibilityIdentifier("competitionEndShareButton")

                ghostButton(title: "Full standings", icon: "list.number", color: Color("Brand")) {
                    if let competition = viewModel.currentEndCompetition {
                        onViewStandings(competition)
                    }
                    dismissSheet()
                }
                .accessibilityIdentifier("competitionEndStandingsButton")
            }
        }
        .padding(.top, 4)
    }

    private func ghostButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 14.5, weight: .semibold))
                Text(title)
                    .font(.system(size: 14.5, weight: .semibold))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color("Surface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color("BorderStrong"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Share

    private func presentShare() {
        var items: [Any] = []
        if let image = renderShareCard() {
            items.append(image)
        }
        items.append(viewModel.shareText)
        if let url = URL(string: CompetitionEndAlertViewModel.appStoreURL) {
            items.append(url)
        }
        shareItems = items
        showingShare = true
    }

    private func renderShareCard() -> UIImage? {
        let card = CompetitionShareCardView(
            outcome: viewModel.endOutcome,
            competitionName: viewModel.currentEndCompetition?.competitionName ?? "",
            accent: viewModel.headlineAccent,
            entries: viewModel.podiumEntries,
            scoringUnit: viewModel.currentEndCompetition?.scoringUnit ?? .points,
            placement: viewModel.userPlacement,
            youFinishedTitle: youFinishedTitle,
            subline: viewModel.outcomeSubline,
            score: viewModel.userScoreValue,
            unitTag: viewModel.unitTagText
        )
        // Force light mode so the shared card reads consistently regardless of device appearance.
        let renderer = ImageRenderer(content: card.environment(\.colorScheme, .light))
        renderer.scale = max(displayScale, 3)
        return renderer.uiImage
    }
}

// MARK: - Shared podium visualization (top-3 pedestals)

/// The top-3 podium used by both the result sheet and the rendered share card. Stage order
/// left → right is 2nd · 1st · 3rd (center-tallest). The current user's pedestal — when they're
/// on the podium — gets the brand-gradient highlight.
struct CompetitionPodiumView: View {
    let entries: [CompetitionEndAlertViewModel.PodiumEntry]
    let scoringUnit: ScoringUnit

    var body: some View {
        let byPosition = Dictionary(uniqueKeysWithValues: entries.map { ($0.position, $0) })
        let staged = [byPosition[2], byPosition[1], byPosition[3]].compactMap { $0 }
        return HStack(alignment: .bottom, spacing: 10) {
            ForEach(staged) { entry in
                column(entry)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func column(_ entry: CompetitionEndAlertViewModel.PodiumEntry) -> some View {
        let isYou = entry.isCurrentUser
        let medal = MedalPalette.color(for: entry.position)

        return VStack(spacing: 0) {
            FWFAvatar(name: isYou ? "You" : entry.displayName,
                      size: entry.position == 1 ? 46 : 38,
                      ring: medal)

            Text(isYou ? "You" : entry.firstName)
                .font(.system(size: 12, weight: isYou ? .bold : .semibold))
                .foregroundStyle(Color("Ink"))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.top, 7)

            Text(pointsText(entry.points))
                .font(.system(size: 12.5, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Color("Ink"))
                .padding(.top, 1)

            pedestal(entry: entry, highlighted: isYou, medal: medal)
                .padding(.top, 8)
        }
        .frame(width: 84)
    }

    @ViewBuilder
    private func pedestal(entry: CompetitionEndAlertViewModel.PodiumEntry,
                          highlighted: Bool,
                          medal: Color?) -> some View {
        let height: CGFloat = {
            switch entry.position {
            case 1: return 64
            case 2: return 44
            default: return 32
            }
        }()
        let shape = UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10, style: .continuous)
        let numberColor: Color = highlighted ? .white : (medal ?? Color("InkMute"))

        ZStack {
            if highlighted {
                shape.fill(LinearGradient(colors: [Color("Brand"), Color("BrandHi")],
                                          startPoint: .top, endPoint: .bottom))
            } else if entry.position == 1 {
                // color-mix(gold 26%, surface-alt)
                shape.fill(Color("SurfaceAlt"))
                shape.fill(Color("Gold").opacity(0.26))
            } else {
                shape.fill(Color("SurfaceAlt"))
                shape.strokeBorder(Color("Border"), lineWidth: 1)
            }

            Text("\(entry.position)")
                .font(.system(size: 16, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(numberColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }

    private func pointsText(_ points: Double?) -> String {
        guard let points else { return "—" }
        return ScoringValueFormatter.formatCompact(points, unit: scoringUnit)
    }
}

// MARK: - Shared "You finished" summary row

/// The brand-tinted "you" treatment summarizing the user's final placement, score, and the
/// outcome subline. Shared by the result sheet and the rendered share card.
struct CompetitionResultSummaryRow: View {
    let placement: Int?
    let title: String
    let subline: String
    let score: String
    let unitTag: String

    var body: some View {
        let medal = MedalPalette.color(for: placement)
        HStack(spacing: 11) {
            ZStack {
                if let medal {
                    Circle().fill(medal)
                } else {
                    Circle().fill(Color("SurfaceAlt"))
                    Circle().strokeBorder(Color("Border"), lineWidth: 1)
                }
                if let placement {
                    Text("\(placement)")
                        .font(.system(size: 13, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(medal != nil ? .white : Color("InkSoft"))
                }
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundStyle(Color("Ink"))
                Text(subline)
                    .font(.system(size: 12))
                    .foregroundStyle(Color("InkSoft"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 0) {
                Text(score)
                    .font(.system(size: 19, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(Color("Brand"))
                Text(unitTag)
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.9)
                    .foregroundStyle(Color("InkMute"))
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color("BrandSoft"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color("Brand"), lineWidth: 1.5)
        )
    }
}

// MARK: - Share card (rendered to an image)

/// A self-contained, fixed-size result card rasterized by `ImageRenderer` for the system share
/// sheet. Mirrors the sheet's visual language (brand-gradient cap on a win, podium, "you finished"
/// row) plus a wordmark footer, sized for social/message sharing.
struct CompetitionShareCardView: View {
    let outcome: CompetitionEndAlertViewModel.EndOutcome
    let competitionName: String
    let accent: String
    let entries: [CompetitionEndAlertViewModel.PodiumEntry]
    let scoringUnit: ScoringUnit
    let placement: Int?
    let youFinishedTitle: String
    let subline: String
    let score: String
    let unitTag: String

    private var won: Bool { outcome == .won }

    var body: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 16) {
                CompetitionPodiumView(entries: entries, scoringUnit: scoringUnit)
                CompetitionResultSummaryRow(placement: placement,
                                            title: youFinishedTitle,
                                            subline: subline,
                                            score: score,
                                            unitTag: unitTag)
                Spacer(minLength: 0)
                footer
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color("Surface"))
        }
        .frame(width: 340, height: 460)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                if won {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("Final results")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(1.05)
                    .textCase(.uppercase)
                    .foregroundStyle(won ? Color.white.opacity(0.82) : Color("InkSoft"))
            }

            (
                Text(competitionName + "\n")
                    .foregroundColor(won ? .white : Color("Ink"))
                + Text(accent)
                    .italic()
                    .foregroundColor(won ? Color.white.opacity(0.82) : Color("InkSoft"))
            )
            .font(.system(size: 24, weight: .regular, design: .serif))
            .tracking(-0.48)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(headerBackground)
    }

    @ViewBuilder
    private var headerBackground: some View {
        if won {
            LinearGradient(colors: [Color("BrandHi"), Color("Brand")],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        } else {
            Color("SurfaceAlt")
        }
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color("Brand"))
            Text("Fit with Friends")
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(Color("InkMute"))
        }
        .frame(maxWidth: .infinity)
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
