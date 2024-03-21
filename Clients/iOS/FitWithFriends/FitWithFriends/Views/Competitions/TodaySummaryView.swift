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
                                      currentValue: activitySummary.activeCaloriesBurned ?? 0,
                                      goal: activitySummary.activeCaloriesGoal ?? 0)
                        .padding(.bottom, 5)

                    ActivityValueView(name: "Exercise",
                                      unit: "Min",
                                      color: Color(red: 0.259, green: 0.914, blue: 0),
                                      currentValue: activitySummary.exerciseTime ?? 0,
                                      goal: activitySummary.exerciseTimeGoal ?? 0)
                        .padding(.bottom, 5)

                    ActivityValueView(name: "Stand",
                                      unit: "h",
                                      color: Color(red: 0.254, green: 0.749, blue: 0.847),
                                      currentValue: activitySummary.standTime ?? 0,
                                      goal: activitySummary.standTimeGoal ?? 0)
                }
                .padding(.leading)
                .padding(.trailing)
                .padding(.bottom)

                Spacer()

                if let summary = activitySummary.activitySummary {
                    ActivityRingView(activitySummary: summary)
                        .frame(width: 120, height: 120, alignment: .center)
                        .padding()
                }
            }
        }
        .background(Color.secondarySystemBackground)
    }
}

struct TodaySummaryView_Previews: PreviewProvider {
    private static var activitySummary: ActivitySummary {
        let hkActivitySummary = HKActivitySummary(activeEnergyBurned: 51.027,
                                                  activeEnergyBurnedGoal: 700,
                                                  exerciseTime: 12.3,
                                                  exerciseTimeGoal: 30,
                                                  standTime: 4,
                                                  standTimeGoal: 12)
        return ActivitySummary(activitySummary: hkActivitySummary)!
    }

    static var previews: some View {
        TodaySummaryView(activitySummary: activitySummary,
        homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(), healthKitManager: MockHealthKitManager()),
        objectGraph: MockObjectGraph())
    }
}
