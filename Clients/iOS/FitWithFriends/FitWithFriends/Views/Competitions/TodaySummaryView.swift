//
//  TodaySummaryView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import SwiftUI
import HealthKit

struct TodaySummaryView: View {
    let activitySummary: HKActivitySummary

    var body: some View {
        VStack {
            HStack {
                Text("\(Int(activitySummary.competitionPoints)) points so far today!")
                    .padding()
                    .font(.title3)
                Spacer()
            }

            HStack {
                VStack {
                    ActivityValueView(name: "Move",
                                      unit: "Cal",
                                      color: Color(red: 0.914, green: 0.078, blue: 0.204),
                                      currentValue: activitySummary.activeEnergyBurned.doubleValue(for: .kilocalorie()),
                                      goal: activitySummary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()))
                        .padding(.bottom, 5)

                    ActivityValueView(name: "Exercise",
                                      unit: "Min",
                                      color: Color(red: 0.259, green: 0.914, blue: 0),
                                      currentValue: activitySummary.appleExerciseTime.doubleValue(for: .minute()),
                                      goal: activitySummary.appleExerciseTimeGoal.doubleValue(for: .minute()))
                        .padding(.bottom, 5)

                    ActivityValueView(name: "Stand",
                                      unit: "h",
                                      color: Color(red: 0.254, green: 0.749, blue: 0.847),
                                      currentValue: activitySummary.appleStandHours.doubleValue(for: .count()),
                                      goal: activitySummary.appleStandHoursGoal.doubleValue(for: .count()))
                }
                .padding(.leading)
                .padding(.trailing)
                .padding(.bottom)

                Spacer()

                ActivityRingView(activitySummary: activitySummary)
                    .frame(width: 120, height: 120, alignment: .center)
                    .padding()
            }
        }
        .background(Color.secondarySystemBackground)
    }
}

struct TodaySummaryView_Previews: PreviewProvider {
    private static var activitySummary: HKActivitySummary {
        let activitySummary = HKActivitySummary()
        activitySummary.activeEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: 351.027)
        activitySummary.appleExerciseTime = HKQuantity(unit: .minute(), doubleValue: 12.3)
        activitySummary.appleStandHours = HKQuantity(unit: .count(), doubleValue: 4)
        activitySummary.appleStandHoursGoal = HKQuantity(unit: .count(), doubleValue: 12)
        activitySummary.appleExerciseTimeGoal = HKQuantity(unit: .minute(), doubleValue: 30)
        activitySummary.activeEnergyBurnedGoal = HKQuantity(unit: .kilocalorie(), doubleValue: 700)

        return activitySummary
    }

    static var previews: some View {
        TodaySummaryView(activitySummary: activitySummary)
    }
}
