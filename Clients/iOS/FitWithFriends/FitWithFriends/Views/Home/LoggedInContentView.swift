//
//  LoggedInContentView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/20.
//

import SwiftUI

struct LoggedInContentView: View {
    @ObservedObject private var permissionPromptViewModel =
        PermissionPromptViewModel(healthKitManager: ObjectGraph.sharedInstance.healthKitManager,
                                  pushNotificationManager: ObjectGraph.sharedInstance.pushNotificationManager)

    var body: some View {
        VStack {
            CompetitionSummaryListView()
//            Text("Logged in!")
//            Button("Logout") {
//                ObjectGraph.sharedInstance.authenticationManager.logout()
//            }
        }
        .sheet(isPresented: $permissionPromptViewModel.shouldShowPermissionPrompt, content: {
            PermissionPromptView(permissionPromptViewModel: permissionPromptViewModel)
        })
    }
}

struct LoggedInContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedInContentView()
    }
}
