//
//  JoinCompetitionViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/21/22.
//

import Combine
import Foundation

public class JoinCompetitionViewModel: ObservableObject {
    @Published var isLoading = true

    @Published var state: ViewOperationState = .notStarted

    var adminName: String
    var competitionName: String
    var competitionDateRange: String
    var competitionMembers: String

    private let appProtocolHandler: AppProtocolHandler
    private let competitionManager: CompetitionManager
    private let homepageSheetViewModel: HomepageSheetViewModel

    init(appProtocolHandler: AppProtocolHandler, competitionManager: CompetitionManager, homepageSheetViewModel: HomepageSheetViewModel) {
        self.appProtocolHandler = appProtocolHandler
        self.competitionManager = competitionManager
        self.homepageSheetViewModel = homepageSheetViewModel

        adminName = ""
        competitionName = ""
        competitionDateRange = ""
        competitionMembers = ""

        // Fetch the competition description
        Task.detached { [weak self] in
            guard let self = self else { return }

            guard let joinCompetitionProtocolData = self.appProtocolHandler.protocolData as? JoinCompetitionProtocolData else {
                return
            }

            do {
                let description = try await self.competitionManager.getCompetitionDescription(for: joinCompetitionProtocolData.competitionId,
                                                                                              competitionToken: joinCompetitionProtocolData.competitionToken)

                self.adminName = "Created by " + description.adminName
                self.competitionName = description.competitionName

                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .none

                let startString = dateFormatter.string(from: description.competitionStart)
                let endString = dateFormatter.string(from: description.competitionEnd)
                self.competitionDateRange = "\(startString) - \(endString)"

                self.competitionMembers = "\(description.numMembers.description) members so far"

                await MainActor.run { [weak self] in
                    self?.isLoading = false
                }
            } catch {
                Logger.traceError(message: "Could not get competition description for \(joinCompetitionProtocolData.competitionId)", error: error)

                // Dismiss the join competition modal
                homepageSheetViewModel.updateState(sheet: .joinCompetition, state: false)
            }
        }
    }

    func joinCompetition() async  {
        guard let joinCompetitionProtocolData = appProtocolHandler.protocolData as? JoinCompetitionProtocolData else {
            Logger.traceError(message: "Could not get join competition data from protocol handler", error: nil)
            await MainActor.run {
                self.state = .failed(errorMessage: "Unexpected error")
            }

            return
        }

        let newState: ViewOperationState
        do {
            try await competitionManager.joinCompetition(competitionId: joinCompetitionProtocolData.competitionId,
                                                         competitionToken: joinCompetitionProtocolData.competitionToken)

            // Refresh the competitions list and dismiss the modal
            Logger.traceInfo(message: "Successfully joined competition \(joinCompetitionProtocolData.competitionId.description)")
            newState = .success

            await competitionManager.refreshCompetitionOverviews()
            homepageSheetViewModel.updateState(sheet: .joinCompetition, state: false)
        } catch {
            Logger.traceError(message: "Failed to join competition \(joinCompetitionProtocolData.competitionId.description)", error: error)

            var errorMessage = error.localizedDescription

            // Check for a more specific error message
            if let errorWithDetails = error as? ErrorWithDetails,
               let details = errorWithDetails.errorDetails {
                switch (details.fwfErrorCode) {
                case .tooManyActiveCompetitions:
                    errorMessage = "Too many active competitions"
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
