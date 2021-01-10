//
//  AppStateViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/23/20.
//

import Combine
import Foundation

class AppStateViewModel: ObservableObject {
    @Published var isLoggedIn = false

    private var loginCancellable: AnyCancellable?

    init() {
        loginCancellable = ObjectGraph.sharedInstance.authenticationManager.$loginState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                switch value {
                case .loggedIn:
                    self?.isLoggedIn = true
                default:
                    self?.isLoggedIn = false
                }
            }
    }
}
