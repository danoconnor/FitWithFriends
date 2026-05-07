//
//  WatchUserCompetitionDailyDetailsView.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 5/6/26.
//

import SwiftUI

struct WatchUserCompetitionDailyDetailsView: View {
    @StateObject private var viewModel: UserCompetitionDailyDetailsViewModel

    init(competitionId: UUID, userId: String, userName: String, competitionManager: ICompetitionManager) {
        _viewModel = StateObject(wrappedValue: UserCompetitionDailyDetailsViewModel(
            competitionManager: competitionManager,
            competitionId: competitionId,
            userId: userId,
            userName: userName))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else if viewModel.dailySummaries.isEmpty {
                Text("No activity yet")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                List {
                    Section {
                        ForEach(viewModel.dailySummaries) { summary in
                            WatchDailySummaryRow(summary: summary, unit: viewModel.scoringUnit)
                        }
                    } header: {
                        VStack(spacing: 2) {
                            Text(ScoringValueFormatter.format(viewModel.totalPoints, unit: viewModel.scoringUnit))
                                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                            Text(viewModel.totalLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                }
                #if os(watchOS)
                .listStyle(.carousel)
                #endif
            }
        }
        .navigationTitle(viewModel.userName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDetails()
        }
    }
}

// MARK: - Daily row

struct WatchDailySummaryRow: View {
    let summary: DailySummary
    let unit: ScoringUnit

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: summary.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(dateString)
                    .font(.footnote.weight(.semibold))
                Spacer()
                Text(ScoringValueFormatter.format(summary.points, unit: unit))
                    .font(.footnote.weight(.semibold).monospacedDigit())
            }

            if unit == .points {
                Text("\(summary.caloriesBurned)/\(summary.caloriesGoal) Cal · \(summary.exerciseTime)/\(summary.exerciseTimeGoal) Min · \(summary.standTime)/\(summary.standTimeGoal) h")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}
