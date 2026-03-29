//
//  AboutCompetitions.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/23/22.
//

import SwiftUI

struct AboutCompetitionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("This app allows you to compete in fitness competitions with groups of friends. You earn points by closing your Apple activity rings each day. You can earn up to 600 points per day, so get out there and get active!")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("How to create a new competition?")
                        .font(.headline)

                    Text("This one is easy - go to the homepage of this app and use the 'Create new competition' button. Once the competition is created, tap the '...' button and select 'Share' to create an access link that can be shared with your friends and allow them to join the competition.")
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("How to join an existing competition?")
                        .font(.headline)

                    Text("To join a competition that someone else created, you will need to get an access link from them. They can create the access link by selecting the competition on their device, tapping the '...' button, and using the 'Share' button to create and send the access link to you. The access link will open in your Fit with Friends app and show a dialog asking you to confirm that you want to join the competition.")
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("How does scoring work?")
                        .font(.headline)

                    Text("You get one point for each percent of each ring that you close. So if you close 50% of your move ring, 125% of your exercise ring, and 75% of your stand ring, then you will earn 250 points for that day. You can only earn 600 points per day, any ring progress after that won't count towards your score.")
                        .foregroundStyle(.secondary)

                    Text("Since points are based on ring percentages, the ring goals you set in Apple Health are important! If you set goals that are too low, then you will earn points too easily and vice versa. Make sure that you set appropriate ring goals so you compete fairly with your friends.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .padding(16)
        }
        .navigationTitle("About competitions")
    }
}

struct AboutCompetitionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutCompetitionsView()
        }
    }
}
