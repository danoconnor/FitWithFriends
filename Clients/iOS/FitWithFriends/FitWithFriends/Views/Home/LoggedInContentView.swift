//
//  LoggedInContentView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/20.
//

import SwiftUI

struct LoggedInContentView: View {
    private let objectGraph: IObjectGraph

    @ObservedObject private var homepageSheetViewModel: HomepageSheetViewModel

    init(objectGraph: IObjectGraph) {
        self.objectGraph = objectGraph
        homepageSheetViewModel = HomepageSheetViewModel(healthKitManager: objectGraph.healthKitManager)
    }

    var body: some View {
        VStack {
            Button(action: {
                homepageSheetViewModel.updateState(sheet: .createCompetition, state: true)
            }, label: {
                Text("New competition")
            })
            .padding()

            Button(action: {
                objectGraph.authenticationManager.logout()
            }, label: {
                Text("Logout")
            })
            .padding()
        }
        .sheet(isPresented: $homepageSheetViewModel.shouldShowSheet, content: {
            switch homepageSheetViewModel.sheetToShow {
            case .createCompetition:
                CreateCompetitionView(homepageSheetViewModel: homepageSheetViewModel, objectGraph: objectGraph)
            case .permissionPrompt:
                PermissionPromptView(homepageSheetViewModel: homepageSheetViewModel, objectGraph: objectGraph)
            default:
                Text("Unknown sheet type: \(homepageSheetViewModel.sheetToShow.rawValue)")
            }
        })
    }
}

struct LoggedInContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedInContentView(objectGraph: MockObjectGraph())
    }
}
