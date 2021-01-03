//
//  PermissionPromptView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/20.
//

import SwiftUI

struct PermissionPromptView: View {
    @ObservedObject var permissionPromptViewModel: PermissionPromptViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("We need a couple permissions to get started")
                .font(.title)
                .padding()

            ScrollView {
                VStack(alignment: .leading) {
                    Section {
                        HStack {
                            if permissionPromptViewModel.shouldPromptForHealth {
                                Text("1.")
                                    .font(.title2)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }

                            Text("Health data")
                                .font(.title2)
                        }

                        Text("We need to access your activity and workout data in order to count it towards your competition points.")

                        Text ("We take your privacy seriously and do not share your data with any 3rd parties or advertisers. Only you and the people in your competition group will have access to it.")
                    }
                    .padding()

                    Section {
                        HStack {
                            if permissionPromptViewModel.shouldPromptForNotifications {
                                Text("2.")
                                    .font(.title2)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }

                            Text("Push notifications (optional)")
                                .font(.title2)
                        }

                        Text("If you choose to grant access to push notifications, we send you updates about your competitions.")
                    }
                    .padding()
                }
            }

            Spacer()

            Section {
                VStack(alignment: .center) {
                    Button("Next") {
                        if permissionPromptViewModel.shouldPromptForHealth {
                            permissionPromptViewModel.requestHealthPermission()
                        } else if permissionPromptViewModel.shouldPromptForNotifications {
                            permissionPromptViewModel.requestNotificationPermission()
                        }
                    }
                    .font(.title2)

                    Button("Not now") {
                        permissionPromptViewModel.shouldShowPermissionPrompt = false
                    }
                    .font(.footnote)
                    .padding(.top, 5)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
}

struct PermissionPromptView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionPromptView(permissionPromptViewModel: PermissionPromptViewModel(healthKitManager: ObjectGraph.sharedInstance.healthKitManager, pushNotificationManager: ObjectGraph.sharedInstance.pushNotificationManager))
    }
}
