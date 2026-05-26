//
//  TodaySummaryView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//
//  The activity-first today panel on the home screen — rings + an editorial
//  sentence headline + a horizontally-scrolling strip of universal activity
//  metrics (move/exercise/stand/steps). Replaces the old single-headline
//  "points today" panel, which broke when a user was in multiple comps with
//  different scoring rules.
//

import SwiftUI
import HealthKit

struct TodaySummaryView: View {
    let activitySummary: ActivitySummary
    let headline: HomepageViewModel.TodayRingsHeadline
    let stripItems: [HomepageViewModel.ActivityStripItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                ActivityRingView(activitySummary: activitySummary.hkActivitySummary)
                    .frame(width: 92, height: 92)

                FWFDisplay(
                    parts: [
                        (headline.prefix + " ", false),
                        (headline.accent, true)
                    ],
                    size: 26,
                    color: Color("Ink"),
                    italicColor: headline.isCelebration ? Color("Exercise") : Color("InkSoft")
                )

                Spacer(minLength: 0)
            }

            if !stripItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(stripItems) { item in
                            ActivityStripCard(item: item)
                        }
                    }
                }
            }
        }
    }
}

private struct ActivityStripCard: View {
    let item: HomepageViewModel.ActivityStripItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color("InkMute"))

            Text(item.value)
                .font(.system(size: 22, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Color("Ink"))

            if let goalDescription = item.goalDescription {
                Text(goalDescription)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Color("InkFaint"))
            }

            if item.progress > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: item.tintHex).opacity(0.15))
                            .frame(height: 3)
                        Capsule()
                            .fill(Color(hex: item.tintHex))
                            .frame(width: geo.size.width * item.progress, height: 3)
                    }
                }
                .frame(height: 3)
            } else {
                // Reserve space so cards stay the same height.
                Color.clear.frame(height: 3)
            }
        }
        .padding(12)
        .frame(width: 110, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color("Bg"))
        )
    }
}

struct TodaySummaryView_Previews: PreviewProvider {
    private static var activitySummary: ActivitySummary {
        let summaryDTO = ActivitySummaryDTO(date: Date(),
                                            activeEnergyBurned: 510,
                                            activeEnergyBurnedGoal: 700,
                                            appleExerciseTime: 32,
                                            appleExerciseTimeGoal: 30,
                                            appleStandHours: 9,
                                            appleStandHoursGoal: 12)
        return ActivitySummary(activitySummary: summaryDTO)
    }

    static var previews: some View {
        TodaySummaryView(
            activitySummary: activitySummary,
            headline: .init(prefix: "2 rings closed,", accent: "one to go.", isCelebration: true),
            stripItems: [
                .init(id: "move", label: "Move", value: "510", goalDescription: "of 700 cal", progress: 0.72, tintHex: "FA114F"),
                .init(id: "exercise", label: "Exercise", value: "32", goalDescription: "of 30 min", progress: 1.0, tintHex: "92E82A"),
                .init(id: "stand", label: "Stand", value: "9", goalDescription: "of 12 hr", progress: 0.75, tintHex: "1EEAEF"),
                .init(id: "steps", label: "Steps", value: "8,420", goalDescription: "today", progress: 0, tintHex: "2A3F7A"),
            ]
        )
        .fwfCard()
        .padding(.horizontal, 16)
        .background(Color("Bg"))
    }
}
