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
        VStack {
            Text("\(Int(activitySummary.competitionPoints)) points so far today!")
                .padding()
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                VStack {
                    ActivityValueView(name: "Move",
                                      unit: "Cal",
                                      color: Color(red: 0.914, green: 0.078, blue: 0.204),
                                      currentValue: activitySummary.activeCaloriesBurned,
                                      goal: activitySummary.activeCaloriesGoal)
                        .padding(.bottom, 5)

                    ActivityValueView(name: "Exercise",
                                      unit: "Min",
                                      color: Color(red: 0.259, green: 0.914, blue: 0),
                                      currentValue: activitySummary.exerciseTime,
                                      goal: activitySummary.exerciseTimeGoal)
                        .padding(.bottom, 5)

                    ActivityValueView(name: "Stand",
                                      unit: "h",
                                      color: Color(red: 0.254, green: 0.749, blue: 0.847),
                                      currentValue: activitySummary.standTime,
                                      goal: activitySummary.standTimeGoal)
                }
                .padding(.leading)
                .padding(.trailing)
                .padding(.bottom)

                Spacer()

                ActivityRingView(activitySummary: activitySummary.hkActivitySummary)
                    .frame(width: 120, height: 120, alignment: .center)
                    .padding()
            }
        }
        .background(Color.secondarySystemBackground)
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
    }
}
