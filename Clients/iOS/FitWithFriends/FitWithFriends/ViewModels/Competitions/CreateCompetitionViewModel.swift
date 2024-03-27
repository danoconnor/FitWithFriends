//
//  CreateCompetitionViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/27/21.
//

import Foundation
import SwiftUI

public class CreateCompetitionViewModel: ObservableObject {
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
                    var errorMessage = error.localizedDescription

                    // Check to see if we have a more specific error code
                    if let errorWithDetails = error as? ErrorWithDetails,
                       let details = errorWithDetails.errorDetails {
                        switch details.fwfErrorCode {
                        case .tooManyActiveCompetitions:
                            errorMessage = "Too many active competitions"
                        default:
                            break
                        }
                    }

                    self.state = .failed(errorMessage: errorMessage)
                } else {
                    self.state = .success
                    self.homepageSheetViewModel.updateState(sheet: .createCompetition, state: false)
                }
            }
        }
    }
}
