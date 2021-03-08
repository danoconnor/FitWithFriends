//
//  LoggedInContentView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/20.
//

import SwiftUI

struct LoggedInContentView: View {
    @ObservedObject private var homepageSheetViewModel: HomepageSheetViewModel

    init() {
        homepageSheetViewModel = HomepageSheetViewModel()

        // Check if we need to show the permission prompt
        if ObjectGraph.sharedInstance.healthKitManager.shouldPromptUser ||
            ObjectGraph.sharedInstance.pushNotificationManager.shouldPromptUser {
            homepageSheetViewModel.updateState(sheet: .permissionPrompt, state: true)
        }
    }

    var body: some View {
        VStack {
            CompetitionSummaryListView()

            Button(action: {
                homepageSheetViewModel.updateState(sheet: .createCompetition, state: true)
            }, label: {
                Text("New competition")
            })
            .padding()

            Button(action: {
                ObjectGraph.sharedInstance.authenticationManager.logout()
            }, label: {
                Text("Logout")
            })
            .padding()
        }
        .sheet(isPresented: $homepageSheetViewModel.shouldShowSheet, content: {
            switch homepageSheetViewModel.sheetToShow {
            case .createCompetition:
                CreateCompetitionView(homepageSheetViewModel: homepageSheetViewModel)
            case .permissionPrompt:
                PermissionPromptView(homepageSheetViewModel: homepageSheetViewModel)
            default:
                Text("Unknown sheet type: \(homepageSheetViewModel.sheetToShow.rawValue)")
            }
        })
    }
}

struct LoggedInContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedInContentView()
    }
}
