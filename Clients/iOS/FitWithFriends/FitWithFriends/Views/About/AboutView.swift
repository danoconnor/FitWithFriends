//
//  AboutView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/23/22.
//

import SwiftUI

struct AboutView: View {
    let emailUtility: IEmailUtility
    let serverEnvironmentManager: IServerEnvironmentManager

    var body: some View {
        NavigationView {
            List {
                Section {
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                    LabeledContent("Version", value: version ?? "Unknown")
                    LabeledContent("Developer", value: SecretConstants.developerName)
                    HStack {
                        Text("Contact")
                        Spacer()
                        Link(SecretConstants.supportEmail,
                             destination: URL(string: "mailto:\(SecretConstants.supportEmail)")!)
                            .foregroundStyle(.blue)
                    }
                }

                Section("Help") {
                    NavigationLink {
                        AboutCompetitionsView()
                    } label: {
                        Label("How do competitions work?", systemImage: "trophy")
                    }

                    NavigationLink {
                        AboutHealthDataView()
                    } label: {
                        Label("Activity data troubleshooting", systemImage: "heart.text.square")
                    }
                }

                Section("More") {
                    Button {
                        self.emailUtility.sendLogEmail()
                    } label: {
                        Label("Send diagnostic logs", systemImage: "envelope")
                    }

                    Link(destination: URL(string: "\(serverEnvironmentManager.baseUrl)/privacyPolicy")!) {
                        Label("Privacy policy", systemImage: "hand.raised")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("About")
        }
        .presentationDragIndicator(.visible)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(emailUtility: MockEmailUtility(),
                  serverEnvironmentManager: ServerEnvironmentManager(userDefaults: UserDefaults.standard))
    }
}
