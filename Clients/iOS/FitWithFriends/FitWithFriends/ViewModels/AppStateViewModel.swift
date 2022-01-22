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

    private let authenticationManager: AuthenticationManager
    private var loginCancellable: AnyCancellable?

    init(authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        loginCancellable = authenticationManager.$loginState
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
