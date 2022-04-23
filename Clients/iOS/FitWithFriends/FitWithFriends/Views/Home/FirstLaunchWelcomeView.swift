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
        VStack(alignment: .leading) {
            ScrollView {
                VStack {
                    Text("Welcome to Fit with Friends!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                        .padding(.leading)
                        .padding(.trailing)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)


                    Text("This app allows you to compete in fitness competitions with groups of friends. You earn points by closing your Apple activity rings each day. You can earn up to 600 points per day, so get out there and get active!")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("You will need an Apple Watch to be able to participate in competitions - it's how you earn progress on your rings. So be sure to wear your Watch throughout the day so your move, exercise, and stand rings progress and you get credit for your hard work.")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Login on the next page to get started. From there you can create a new competition group and invite your friends. Or you can join an existing group by getting an access link from the person who created the competition.")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer()

            Section {
                VStack(alignment: .center) {
                    Button("Continue") {
                        self.welcomeViewModel.dismissFirstLaunchView()
                    }
                    .font(.title)
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
}

struct FirstLaunchWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        FirstLaunchWelcomeView(welcomeViewModel: WelcomeViewModel(authenticationManager: MockAuthenticationManager()))
    }
}
