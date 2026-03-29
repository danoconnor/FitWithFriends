//
//  FirstLaunchWelcomeView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/23/22.
//

import SwiftUI

struct FirstLaunchWelcomeView: View {
    let welcomeViewModel: WelcomeViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Gradient header
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color("FwFBrandingColor"),
                                Color("FwFBrandingColor").opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Text("Welcome to\nFit with Friends!")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 32)
                            .padding(.horizontal)
                    }

                    // Feature rows
                    VStack(alignment: .leading, spacing: 24) {
                        FWFFeatureRow(
                            icon: "figure.run",
                            color: .red,
                            title: "Compete with Friends",
                            description: "Earn points by closing your Apple activity rings each day. You can earn up to 600 points per day, so get out there and get active!"
                        )

                        FWFFeatureRow(
                            icon: "applewatch",
                            color: Color("FwFBrandingColor"),
                            title: "Apple Watch Required",
                            description: "You'll need an Apple Watch to participate. Wear it throughout the day so your move, exercise, and stand rings progress."
                        )

                        FWFFeatureRow(
                            icon: "person.3.fill",
                            color: .green,
                            title: "Create or Join",
                            description: "Create a new competition and invite your friends, or join an existing group with an access link."
                        )
                    }
                    .padding(24)
                }
            }

            // Continue button
            FWFPrimaryButton("Continue") {
                self.welcomeViewModel.dismissSheet()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

struct FirstLaunchWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        FirstLaunchWelcomeView(welcomeViewModel: WelcomeViewModel(authenticationManager: MockAuthenticationManager()))
    }
}
