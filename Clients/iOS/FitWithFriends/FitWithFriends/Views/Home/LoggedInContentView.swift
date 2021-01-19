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

            Button(action: {
                ObjectGraph.sharedInstance.authenticationManager.logout()
            }, label: {
                Text("Logout")
            })
            .padding()
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
