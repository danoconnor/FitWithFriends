//
//  SettingsView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/23/22.
//

import SwiftUI

struct SettingsView: View {
    let emailUtility: IEmailUtility
    let serverEnvironmentManager: IServerEnvironmentManager
    let onDeleteAccount: () async -> Bool

    @State private var showDeleteAccountAlert = false
    @State private var showDeleteAccountErrorAlert = false

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

                Section("Account") {
                    Button(role: .destructive) {
                        showDeleteAccountAlert = true
                    } label: {
                        Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
        }
        .presentationDragIndicator(.visible)
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    let success = await onDeleteAccount()
                    if !success {
                        showDeleteAccountErrorAlert = true
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete your account and all your data. This cannot be undone.")
        }
        .alert("Error", isPresented: $showDeleteAccountErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to delete your account. Please try again later.")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(emailUtility: MockEmailUtility(),
                     serverEnvironmentManager: ServerEnvironmentManager(userDefaults: UserDefaults.standard),
                     onDeleteAccount: { return true })
    }
}
