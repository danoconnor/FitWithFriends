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
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)

                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.dailySummaries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)

                    Text("No activity data yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header: total points
                        VStack(spacing: 4) {
                            Text("\(Int(viewModel.totalPoints))")
                                .font(.system(size: 36, weight: .bold, design: .rounded))

                            Text("total points")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)

                        // Daily cards
                        ForEach(viewModel.dailySummaries) { summary in
                            DailySummaryCard(summary: summary)
                                .fwfCard()
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle(viewModel.userName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDetails()
        }
    }
}

// MARK: - Daily Summary Card

struct DailySummaryCard: View {
    let summary: DailySummary

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date + points header
            HStack {
                Text(dateString)
                    .font(.headline)
                Spacer()
                Text("\(Int(summary.points)) pts")
                    .font(.headline.weight(.semibold).monospacedDigit())
            }

            HStack(alignment: .center, spacing: 16) {
                ActivityRingView(activitySummary: hkActivitySummary)
                    .frame(width: 80, height: 80)

                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        ActivityValueView(name: "Move",
                                          unit: "Cal",
                                          color: Color(red: 0.914, green: 0.078, blue: 0.204),
                                          currentValue: summary.caloriesBurned,
                                          goal: summary.caloriesGoal)

                        ActivityValueView(name: "Exercise",
                                          unit: "Min",
                                          color: Color(red: 0.259, green: 0.914, blue: 0),
                                          currentValue: summary.exerciseTime,
                                          goal: summary.exerciseTimeGoal)

                        ActivityValueView(name: "Stand",
                                          unit: "h",
                                          color: Color(red: 0.254, green: 0.749, blue: 0.847),
                                          currentValue: summary.standTime,
                                          goal: summary.standTimeGoal)
                    }
                }
            }
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
