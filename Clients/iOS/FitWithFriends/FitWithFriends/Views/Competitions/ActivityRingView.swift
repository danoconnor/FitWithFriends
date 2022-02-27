//
//  ActivityRingView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import Foundation
import HealthKitUI
import SwiftUI

struct ActivityRingView: UIViewRepresentable {
    typealias UIViewType = HKActivityRingView

    private let activitySummary: HKActivitySummary
    init(activitySummary: HKActivitySummary) {
        self.activitySummary = activitySummary
    }

    func makeUIView(context: Context) -> HKActivityRingView {
        let view = HKActivityRingView()
        view.activitySummary = activitySummary

        return view
    }

    func updateUIView(_ uiView: HKActivityRingView, context: Context) {
        uiView.activitySummary = activitySummary
    }
}
