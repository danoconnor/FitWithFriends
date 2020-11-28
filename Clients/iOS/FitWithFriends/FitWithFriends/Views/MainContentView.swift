//
//  MainContentView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/23/20.
//

import Combine
import SwiftUI

struct MainContentView: View {
    @ObservedObject private var viewModel = AppStateViewModel()

    var body: some View {
        if viewModel.isLoggedIn {
            LoggedInContentView()
        } else {
            WelcomeView()
        }
    }
}

struct MainContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
    }
}
