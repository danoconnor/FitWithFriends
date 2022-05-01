//
//  PermissionPromptView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/20.
//

import SwiftUI

struct PermissionPromptView: View {
    private let objectGraph: IObjectGraph
    private let permissionPromptViewModel: PermissionPromptViewModel

    init(homepageSheetViewModel: HomepageSheetViewModel, objectGraph: IObjectGraph) {
        self.objectGraph = objectGraph
        permissionPromptViewModel = PermissionPromptViewModel(healthKitManager: objectGraph.healthKitManager,
                                                              homepageSheetViewModel: homepageSheetViewModel)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                ScrollView {
                    VStack {
                        Text("Please grant access to all requested permissions on the next screen")
                            .font(.title2)
                            .padding(.top)
                            .padding(.leading)
                            .padding(.trailing)
                            .frame(maxWidth: .infinity, alignment: .leading)


                        Text("We need to access your activity and workout data in order to count it towards your competition points. If you don't grant access, then your workout data recorded from this device will not earn you points.")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("We take your privacy seriously and do not share your data with any 3rd parties or advertisers. Only you and the people in your competition group will have access to it.")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("If you wish to change your mind later, you can make changes in the iOS Settings app > Privacy > Health > Fit with Friends.")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer()

                Section {
                    VStack(alignment: .center) {
                        Button("Next") {
                            permissionPromptViewModel.requestHealthPermission()
                        }
                        .font(.title)
                        .buttonStyle(.borderedProminent)

                        Button("Not now") {
                            permissionPromptViewModel.dismiss()
                        }
                        .font(.footnote)
                        .padding(.top, 5)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("Health data access")
        }
    }
}

struct PermissionPromptView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionPromptView(homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(),
                                                                            healthKitManager: MockHealthKitManager()),
                             objectGraph: MockObjectGraph())
    }
}
