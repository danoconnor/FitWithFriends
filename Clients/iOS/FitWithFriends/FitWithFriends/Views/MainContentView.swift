//
//  MainContentView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/23/20.
//

import Combine
import SwiftUI

struct MainContentView: View {
    let objectGraph: IObjectGraph

    @StateObject private var viewModel: AppStateViewModel
    @StateObject private var versionViewModel: AppVersionViewModel

    init(objectGraph: IObjectGraph) {
        self.objectGraph = objectGraph
        _viewModel = StateObject(wrappedValue: AppStateViewModel(authenticationManager: objectGraph.authenticationManager))
        _versionViewModel = StateObject(wrappedValue: AppVersionViewModel(appVersionManager: objectGraph.appVersionManager))
    }

    var body: some View {
        Group {
            if viewModel.isLoggedIn {
                LoggedInContentView(objectGraph: objectGraph)
            } else {
                WelcomeView(objectGraph: objectGraph)
            }
        }
        .task {
            await objectGraph.appVersionManager.checkAppVersion()
        }
        .alert("Update Required",
               isPresented: Binding(
                get: { versionViewModel.alertState == .requiredUpdate },
                set: { _ in }
               )) {
            Button("Update Now") {
                if let url = URL(string: "https://apps.apple.com/app/id6451087375") {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("A required update is available. Please update Fit With Friends to continue.")
        }
        .alert("Update Available",
               isPresented: Binding(
                get: { versionViewModel.alertState == .recommendedUpdate },
                set: { _ in versionViewModel.dismissRecommendedAlert() }
               )) {
            Button("Update Now") {
                if let url = URL(string: "https://apps.apple.com/app/id6451087375") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Later", role: .cancel) {
                versionViewModel.dismissRecommendedAlert()
            }
        } message: {
            Text("A new version of Fit With Friends is available in the App Store.")
        }
    }
}

struct MainContentView_Previews: PreviewProvider {
    static var loggedInObjectGraph: IObjectGraph {
        let authenticationManager = MockAuthenticationManager()
        authenticationManager.loginState = .loggedIn
        let loggedInObjectGraph = MockObjectGraph()
        loggedInObjectGraph.authenticationManager = authenticationManager

        return loggedInObjectGraph
    }

    static var previews: some View {
        MainContentView(objectGraph: MockObjectGraph())
        MainContentView(objectGraph: MainContentView_Previews.loggedInObjectGraph)
    }
}
