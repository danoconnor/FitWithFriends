//
//  TodaySummaryViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/10/22.
//

import Foundation

class TodaySummaryViewModel {
    private let authenticationManager: AuthenticationManager
    private let homepageSheetViewModel: HomepageSheetViewModel

    init(authenticationManager: AuthenticationManager,
         homepageSheetViewModel: HomepageSheetViewModel) {
        self.authenticationManager = authenticationManager
        self.homepageSheetViewModel = homepageSheetViewModel
    }

    func logout() {
        authenticationManager.logout()
    }

    func showAbout() {
        homepageSheetViewModel.updateState(sheet: .about, state: true)
    }
}
