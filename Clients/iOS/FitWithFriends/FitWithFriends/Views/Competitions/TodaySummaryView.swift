//
//  TodaySummaryView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import SwiftUI
import HealthKit

struct TodaySummaryView: View {
    private let activitySummary: ActivitySummary

    init(activitySummary: ActivitySummary, homepageSheetViewModel: HomepageSheetViewModel, objectGraph: IObjectGraph) {
        self.activitySummary = activitySummary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Points header with activity ring
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(activitySummary.competitionPoints))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text("points today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ActivityRingView(activitySummary: activitySummary.hkActivitySummary)
                    .frame(width: 100, height: 100)
            }

            Divider()

            // Activity metrics
            HStack(spacing: 16) {
                ActivityValueView(name: "Move",
                                  unit: "Cal",
                                  color: Color(red: 0.914, green: 0.078, blue: 0.204),
                                  currentValue: activitySummary.activeCaloriesBurned,
                                  goal: activitySummary.activeCaloriesGoal)

                ActivityValueView(name: "Exercise",
                                  unit: "Min",
                                  color: Color(red: 0.259, green: 0.914, blue: 0),
                                  currentValue: activitySummary.exerciseTime,
                                  goal: activitySummary.exerciseTimeGoal)

                ActivityValueView(name: "Stand",
                                  unit: "h",
                                  color: Color(red: 0.254, green: 0.749, blue: 0.847),
                                  currentValue: activitySummary.standTime,
                                  goal: activitySummary.standTimeGoal)
            }
        }
    }
}

struct TodaySummaryView_Previews: PreviewProvider {
    private static var activitySummary: ActivitySummary {
        let summaryDTO = ActivitySummaryDTO(date: Date(),
                                            activeEnergyBurned: 51,
                                            activeEnergyBurnedGoal: 700,
                                            appleExerciseTime: 12,
                                            appleExerciseTimeGoal: 30,
                                            appleStandHours: 4,
                                            appleStandHoursGoal: 12)
        return ActivitySummary(activitySummary: summaryDTO)
    }

    static var previews: some View {
        TodaySummaryView(activitySummary: activitySummary,
        homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(), healthKitManager: MockHealthKitManager()),
        objectGraph: MockObjectGraph())
            .fwfCard()
            .padding(.horizontal, 16)
    }
}
