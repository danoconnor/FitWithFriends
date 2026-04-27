//
//  CreateCompetitionViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/27/21.
//

import Foundation
import SwiftUI

public class CreateCompetitionViewModel: ObservableObject {
    private let authenticationManager: IAuthenticationManager
    private let competitionManager: ICompetitionManager
    private let subscriptionManager: ISubscriptionManager
    private let homepageSheetViewModel: HomepageSheetViewModel

    @Published var state: ViewOperationState = .notStarted

    /// Scoring rule the user is currently configuring. Defaults to legacy activity rings.
    @Published var scoringRules: ScoringRules = .default

    var isUserPro: Bool { subscriptionManager.isUserPro }

    init(authenticationManager: IAuthenticationManager,
         competitionManager: ICompetitionManager,
         subscriptionManager: ISubscriptionManager,
         homepageSheetViewModel: HomepageSheetViewModel) {
        self.authenticationManager = authenticationManager
        self.competitionManager = competitionManager
        self.subscriptionManager = subscriptionManager
        self.homepageSheetViewModel = homepageSheetViewModel
    }

    func createCompetition(competitionName: String, startDate: Date, endDate: Date) {
        guard competitionName.count > 0 else {
            state = .failed(errorMessage: "Please enter a competition name")
            return
        }

        let rules = scoringRules

        Task.detached { [weak self] in
            guard let self = self else { return }

            let newState: ViewOperationState
            do {
                try await self.competitionManager.createCompetition(startDate: startDate,
                                                                    endDate: endDate,
                                                                    competitionName: competitionName,
                                                                    scoringRules: rules)
                newState = .success
                self.homepageSheetViewModel.updateState(sheet: .createCompetition, state: false)
            } catch {
                var errorMessage = error.localizedDescription

                // Check to see if we have a more specific error code
                if let errorWithDetails = error as? ErrorWithDetails,
                   let details = errorWithDetails.errorDetails {
                    switch details.fwfErrorCode {
                    case .tooManyActiveCompetitions:
                        errorMessage = "Too many active competitions"
                    case .proSubscriptionRequired:
                        errorMessage = "A Pro subscription is required to create competitions with custom scoring rules"
                    default:
                        break
                    }
                }

                newState = .failed(errorMessage: errorMessage)
            }

            await MainActor.run {
                self.state = newState
            }
        }
    }
}
