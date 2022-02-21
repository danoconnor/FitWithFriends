//
//  HomePageSheetViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/6/21.
//

import Combine
import Foundation

class HomepageSheetViewModel: ObservableObject {
    // Order is important - sheets listed first will be given precedence over those listed later
    enum HomepageSheet: String, CaseIterable {
        case permissionPrompt
        case joinCompetition
        case createCompetition

        case none
    }

    @Published var shouldShowSheet = false
    var sheetToShow: HomepageSheet = .none

    private let stateQueue = DispatchQueue(label: "HomepageSheetStateQueue")
    private var appProtocolCancellable: AnyCancellable?

    /// Order is important, it will decide the priority order for sheets to be shown
    private var homepageSheetState: [HomepageSheet: Bool] = [
        .permissionPrompt: false,
        .joinCompetition: false,
        .createCompetition: false
    ]

    init(appProtocolHandler: AppProtocolHandler, healthKitManager: HealthKitManager) {
        if healthKitManager.shouldPromptUser {
            updateState(sheet: .permissionPrompt, state: true)
        }

        appProtocolCancellable = appProtocolHandler.$protocolData.sink { [weak self] in
            if let protocolData = $0,
               protocolData is JoinCompetitionProtocolData {
                self?.updateState(sheet: .joinCompetition, state: true)
            }
        }
    }

    func updateState(sheet: HomepageSheet, state: Bool) {
        stateQueue.sync {
            homepageSheetState[sheet] = state

            var foundSheetToShow = false
            for sheet in HomepageSheet.allCases {
                if homepageSheetState[sheet] == true {
                    sheetToShow = sheet
                    foundSheetToShow = true
                    break
                }
            }

            DispatchQueue.main.async {
                self.shouldShowSheet = foundSheetToShow
            }
        }
    }
}
