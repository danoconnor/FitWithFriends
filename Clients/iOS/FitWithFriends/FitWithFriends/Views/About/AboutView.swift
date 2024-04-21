//
//  AboutView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/23/22.
//

import SwiftUI

struct AboutView: View {
    let emailUtility: EmailUtility
    let serverEnvironmentManager: ServerEnvironmentManager

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                ScrollView {
                    Section {
                        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                        Text("Fit with Friends version \(version ?? "unknown")")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)

                        Text("Developed by \(SecretConstants.developerName)")
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            Text("Contact us at ")
                            Link(SecretConstants.supportEmail,
                                 destination: URL(string: "mailto:\(SecretConstants.supportEmail)")!)
                            .padding(.leading, -5)

                            Spacer()
                        }
                        .padding(.bottom)
                    }
                    .padding(.leading)
                    .padding(.trailing)

                    Section {
                        NavigationLink("How do competitions work?", destination: AboutCompetitionsView())
                            .padding(.bottom, 5)

                        NavigationLink("Activity data troubleshooting", destination: AboutHealthDataView())
                            .padding(.bottom, 5)

                        Button("Send diagnostic logs") {
                            self.emailUtility.sendLogEmail()
                        }
                        .padding(.bottom, 5)

                        Link("Download privacy policy",
                             destination: URL(string: "\(serverEnvironmentManager.baseUrl)/FitWithFriendsPrivacyPolicy.docx")!)
                    }
                    .padding(.leading)
                    .padding(.trailing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("About")
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(emailUtility: MockEmailUtility(),
                  serverEnvironmentManager: ServerEnvironmentManager(userDefaults: UserDefaults.standard))
    }
}
