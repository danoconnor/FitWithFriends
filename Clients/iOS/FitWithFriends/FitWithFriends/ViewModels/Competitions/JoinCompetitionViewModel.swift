//
//  JoinCompetitionViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/21/22.
//

import Combine
import Foundation

class JoinCompetitionViewModel: ObservableObject {
    @Published var isLoading = true

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

            let result = await self.competitionManager.getCompetitionDescription(for: joinCompetitionProtocolData.competitionId,
                                                                                 competitionToken: joinCompetitionProtocolData.competitionToken)

            switch result {
            case let .success(description):
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
            case let .failure(error):
                Logger.traceError(message: "Could not get competition description for \(joinCompetitionProtocolData.competitionId)", error: error)

                // Dismiss the join competition modal
                homepageSheetViewModel.updateState(sheet: .joinCompetition, state: false)
            }
        }
    }

    func joinCompetition() async -> Error? {
        guard let joinCompetitionProtocolData = appProtocolHandler.protocolData as? JoinCompetitionProtocolData else {
            Logger.traceError(message: "Could not get join competition data from protocol handler", error: nil)
            return HttpError.generic
        }

        let error =  await competitionManager.joinCompetition(competitionId: joinCompetitionProtocolData.competitionId,
                                                              competitionToken: joinCompetitionProtocolData.competitionToken)

        if let error = error {
            Logger.traceError(message: "Failed to join competition \(joinCompetitionProtocolData.competitionId.description)", error: error)
        } else {
            // No error - refresh the competitions list and dismiss the modal
            Logger.traceInfo(message: "Successfully joined competition \(joinCompetitionProtocolData.competitionId.description)")

            await competitionManager.refreshCompetitionOverviews()
            homepageSheetViewModel.updateState(sheet: .joinCompetition, state: false)
        }

        return error
    }
}
