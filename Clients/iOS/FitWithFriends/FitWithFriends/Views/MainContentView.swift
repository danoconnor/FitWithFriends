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

    @ObservedObject private var viewModel: AppStateViewModel

    init(objectGraph: IObjectGraph) {
        self.objectGraph = objectGraph
        viewModel = AppStateViewModel(authenticationManager: objectGraph.authenticationManager)
    }

    var body: some View {
        if viewModel.isLoggedIn {
            LoggedInContentView(objectGraph: objectGraph)
        } else {
            WelcomeView(objectGraph: objectGraph)
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
