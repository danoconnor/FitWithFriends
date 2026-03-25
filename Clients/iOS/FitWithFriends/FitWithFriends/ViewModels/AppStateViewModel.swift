//
//  AppStateViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/23/20.
//

import Combine
import Foundation

public class AppStateViewModel: ObservableObject {
    @Published var isLoggedIn = false

    private let authenticationManager: IAuthenticationManager
    private var loginCancellable: AnyCancellable?

    init(authenticationManager: IAuthenticationManager) {
        self.authenticationManager = authenticationManager
        loginCancellable = authenticationManager.loginStatePublisher
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
