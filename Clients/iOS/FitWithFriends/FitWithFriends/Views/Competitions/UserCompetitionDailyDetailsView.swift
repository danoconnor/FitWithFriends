//
//  UserCompetitionDailyDetailsView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/9/26.
//

import HealthKit
import SwiftUI

struct UserCompetitionDailyDetailsView: View {
    @StateObject private var viewModel: UserCompetitionDailyDetailsViewModel

    init(competitionId: UUID, userId: String, userName: String, objectGraph: IObjectGraph) {
        _viewModel = StateObject(wrappedValue: UserCompetitionDailyDetailsViewModel(
            competitionManager: objectGraph.competitionManager,
            competitionId: competitionId,
            userId: userId,
            userName: userName))
    }

    init(viewModel: UserCompetitionDailyDetailsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color("Bg").ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.dailySummaries.isEmpty {
                    emptyView
                } else {
                    loadedContent
                }
            }
        }
        .navigationTitle(viewModel.userName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadDetails() }
    }

    // MARK: - Loaded content

    @ViewBuilder
    private var loadedContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                summaryRow
                    .padding(.horizontal, 16)

                heatmapCard
                    .padding(.horizontal, 16)

                dailyRows
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            FWFAvatar(name: viewModel.userName, size: 64)

            Text(viewModel.userName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color("Ink"))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Summary stat row (Total / Daily avg / Streak)

    private var summaryRow: some View {
        HStack(spacing: 10) {
            summaryStat(
                value: ScoringValueFormatter.formatCompact(viewModel.totalPoints, unit: viewModel.scoringUnit),
                label: viewModel.totalLabel.capitalized
            )

            summaryStat(
                value: viewModel.dailyAverageDisplay,
                label: "Daily avg"
            )

            summaryStat(
                value: "\(viewModel.fullRingDayCount)",
                label: "Full-ring days"
            )
        }
    }

    private func summaryStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Color("Ink"))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color("InkMute"))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fwfCard(padding: 12, cornerRadius: 16)
    }

    // MARK: - Heatmap

    @ViewBuilder
    private var heatmapCard: some View {
        let items = viewModel.heatmapIntensities
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Daily intensity")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Color("InkMute"))

                HStack(spacing: 4) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color("Brand").opacity(0.1 + 0.7 * item.intensity))
                            .frame(height: 22)
                    }
                }

                HStack {
                    Text("Less")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color("InkFaint"))
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Color("Brand").opacity(0.1 + 0.18 * Double(i)))
                                .frame(width: 12, height: 6)
                        }
                    }
                    Text("More")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color("InkFaint"))
                    Spacer()
                }
            }
            .fwfCard(padding: 14)
        }
    }

    // MARK: - Per-day rows

    private var dailyRows: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.dailySummaries) { summary in
                DailyBreakdownRow(
                    summary: summary,
                    scoringUnit: viewModel.scoringUnit,
                    isPersonalBest: summary.date == viewModel.personalBestDate
                )
                .fwfCard(padding: 14)
            }
        }
    }

    // MARK: - States

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(Color("InkMute"))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color("InkSoft"))
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk")
                .font(.system(size: 32))
                .foregroundStyle(Color("InkMute"))
            Text("No activity data yet")
                .font(.subheadline)
                .foregroundStyle(Color("InkSoft"))
        }
    }
}

// MARK: - Daily Breakdown Row

private struct DailyBreakdownRow: View {
    let summary: DailySummary
    let scoringUnit: ScoringUnit
    let isPersonalBest: Bool

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: summary.date)
    }

    private var hkActivitySummary: HKActivitySummary {
        let s = HKActivitySummary()
        s.activeEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: Double(summary.caloriesBurned))
        s.activeEnergyBurnedGoal = HKQuantity(unit: .kilocalorie(), doubleValue: Double(summary.caloriesGoal))
        s.appleExerciseTime = HKQuantity(unit: .minute(), doubleValue: Double(summary.exerciseTime))
        s.appleExerciseTimeGoal = HKQuantity(unit: .minute(), doubleValue: Double(summary.exerciseTimeGoal))
        s.appleStandHours = HKQuantity(unit: .count(), doubleValue: Double(summary.standTime))
        s.appleStandHoursGoal = HKQuantity(unit: .count(), doubleValue: Double(summary.standTimeGoal))
        return s
    }

    private var hasRingData: Bool {
        summary.caloriesGoal > 0
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            if hasRingData {
                ActivityRingView(activitySummary: hkActivitySummary)
                    .frame(width: 48, height: 48)
            } else {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundStyle(Color("InkMute"))
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color("SurfaceAlt")))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(dateString)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color("Ink"))

                    if isPersonalBest {
                        FWFTag(text: "Personal best", color: Color("Sun"), background: Color("Sun").opacity(0.18))
                    }
                }

                if hasRingData {
                    HStack(spacing: 10) {
                        ringValueChip(value: "\(summary.caloriesBurned)c", color: Color("Move"))
                        ringValueChip(value: "\(summary.exerciseTime)m", color: Color("Exercise"))
                        ringValueChip(value: "\(summary.standTime)h", color: Color("Stand"))
                    }
                } else if summary.stepCount > 0 {
                    Text("\(summary.stepCount) steps")
                        .font(.system(size: 12))
                        .foregroundStyle(Color("InkSoft"))
                }
            }

            Spacer()

            Text(ScoringValueFormatter.formatCompact(summary.points, unit: scoringUnit))
                .font(.system(size: 17, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color("Ink"))
        }
    }

    private func ringValueChip(value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Color("InkSoft"))
        }
    }
}

// MARK: - Previews

struct UserCompetitionDailyDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserCompetitionDailyDetailsView(
                competitionId: UUID(),
                userId: "user_1",
                userName: "Alice Chen",
                objectGraph: MockObjectGraph())
        }
    }
}
