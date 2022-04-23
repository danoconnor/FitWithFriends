//
//  AboutHealthData.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/23/22.
//

import SwiftUI

struct AboutHealthDataView: View {
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                Text("We need to access your activity and workout data in order to count it towards your competition points. If you don't grant access, then your workout data recorded from this device will not earn you points.")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("If your activity data is not getting counted correctly, please check that you have granted Fit with Friends access to all required Apple Health categories. Go to the iOS Settings app > Privacy > Health > Fit with Friends and make sure all the options are checked. Then close and re-launch the Fit with Friends app.")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("If your activity data is getting counted correcty when you open the app, but not while the app is closed, then please go to iOS Settings > Fit with Friends and make sure that the 'Background App Refresh' setting is enabled.")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle("About activity data")
    }
}

struct AboutHealthDataView_Previews: PreviewProvider {
    static var previews: some View {
        AboutHealthDataView()
    }
}
