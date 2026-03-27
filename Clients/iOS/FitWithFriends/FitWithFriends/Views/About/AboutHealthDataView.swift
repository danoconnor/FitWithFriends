//
//  AboutHealthData.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/23/22.
//

import SwiftUI

struct AboutHealthDataView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("We need to access your activity and workout data in order to count it towards your competition points. If you don't grant access, then your workout data recorded from this device will not earn you points.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Check Permissions", systemImage: "checkmark.shield")
                        .font(.headline)

                    Text("If your activity data is not getting counted correctly, please check that you have granted Fit with Friends access to all required Apple Health categories. Go to iOS Settings > Privacy > Health > Fit with Friends and make sure all the options are checked. Then close and re-launch the Fit with Friends app.")
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

                VStack(alignment: .leading, spacing: 8) {
                    Label("Background App Refresh", systemImage: "arrow.clockwise")
                        .font(.headline)

                    Text("If your activity data is getting counted correctly when you open the app, but not while the app is closed, then please go to iOS Settings > Fit with Friends and make sure that the 'Background App Refresh' setting is enabled.")
                        .foregroundStyle(.secondary)
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
        .navigationTitle("About activity data")
    }
}

struct AboutHealthDataView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutHealthDataView()
        }
    }
}
