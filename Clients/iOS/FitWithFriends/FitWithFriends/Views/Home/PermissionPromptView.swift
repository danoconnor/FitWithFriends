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
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon header
                        Image(systemName: "heart.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.red)
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.red.opacity(0.1))
                            )
                            .padding(.top, 16)

                        // Feature rows
                        VStack(alignment: .leading, spacing: 20) {
                            FWFFeatureRow(
                                icon: "checkmark.shield.fill",
                                color: .green,
                                title: "Grant Access",
                                description: "Please grant access to all requested permissions on the next screen so we can count your activity towards competition points."
                            )

                            FWFFeatureRow(
                                icon: "lock.fill",
                                color: Color("FwFBrandingColor"),
                                title: "Your Privacy",
                                description: "We take your privacy seriously and do not share your data with any 3rd parties or advertisers. Only you and the people in your competition group will have access."
                            )

                            FWFFeatureRow(
                                icon: "gearshape.fill",
                                color: .gray,
                                title: "Change Anytime",
                                description: "You can update permissions later in iOS Settings > Privacy > Health > Fit with Friends."
                            )
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, 16)
                }

                // Buttons
                FWFPrimaryButton("Next") {
                    permissionPromptViewModel.requestHealthPermission()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("Health data access")
        }
        .presentationDragIndicator(.visible)
    }
}

struct PermissionPromptView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionPromptView(homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(),
                                                                            healthKitManager: MockHealthKitManager()),
                             objectGraph: MockObjectGraph())
    }
}
