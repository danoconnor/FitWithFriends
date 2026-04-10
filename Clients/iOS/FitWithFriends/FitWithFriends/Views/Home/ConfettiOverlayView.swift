//
//  ConfettiOverlayView.swift
//  FitWithFriends
//

import ConfettiSwiftUI
import SwiftUI

struct ConfettiOverlayView: View {
    @State private var counter: Int = 0

    var body: some View {
        Color.clear
            .confettiCannon(trigger: $counter, num: 80, openingAngle: .degrees(60),
                            closingAngle: .degrees(120), radius: 400)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear { counter += 1 }
    }
}
