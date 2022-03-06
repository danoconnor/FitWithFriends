//
//  CreateCompetitionViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/27/21.
//

import Foundation
import SwiftUI

class CreateCompetitionViewModel: ObservableObject {
    private let authenticationManager: AuthenticationManager
    private let competitionManager: CompetitionManager
    private let homepageSheetViewModel: HomepageSheetViewModel

    @Published var state: ViewOperationState = .notStarted

    init(authenticationManager: AuthenticationManager,
         competitionManager: CompetitionManager,
         homepageSheetViewModel: HomepageSheetViewModel) {
        self.authenticationManager = authenticationManager
        self.competitionManager = competitionManager
        self.homepageSheetViewModel = homepageSheetViewModel
    }

    deinit {
        // Make sure we reset the homepageSheet state when we leave the page
        homepageSheetViewModel.updateState(sheet: .createCompetition, state: false)
    }

    func createCompetition(competitionName: String, startDate: Date, endDate: Date) {
        guard competitionName.count > 0 else {
            state = .failed(errorMessage: "Please enter a competition name")
            return
        }

        Task.detached { [weak self] in
            guard let self = self else { return }

            let error = await self.competitionManager.createCompetition(startDate: startDate,
                                                                        endDate: endDate,
                                                                        competitionName: competitionName)

            await MainActor.run {
                if let error = error {
                    self.state = .failed(errorMessage: error.localizedDescription)
                } else {
                    self.state = .success
                    self.homepageSheetViewModel.updateState(sheet: .createCompetition, state: false)
                }
            }
        }
    }
}
