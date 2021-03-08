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

    func createCompetition(competitionName: String, startDate: Date, endDate: Date, workoutsOnly: Bool) {
        guard competitionName.count > 0 else {
            state = .failed(errorMessage: "Please enter a competition name")
            return
        }

        competitionManager.createCompetition(startDate: startDate,
                                             endDate: endDate,
                                             competitionName: competitionName,
                                             workoutsOnly: workoutsOnly) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.state = .failed(errorMessage: error.localizedDescription)
                } else {
                    self?.state = .success
                    self?.homepageSheetViewModel.updateState(sheet: .createCompetition, state: false)
                }
            }
        }
    }
}
