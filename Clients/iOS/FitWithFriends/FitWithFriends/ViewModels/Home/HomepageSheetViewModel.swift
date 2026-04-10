//
//  HomePageSheetViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/6/21.
//

import Combine
import Foundation

struct UserDetailsSheetContext {
    let competitionId: UUID
    let userId: String
    let userName: String
}

public class HomepageSheetViewModel: ObservableObject {
    typealias HomepageSheetState = (shouldShow: Bool, contextData: Any?)

    // Order is important - sheets listed first will be given precedence over those listed later
    enum HomepageSheet: String, CaseIterable {
        case permissionPrompt
        case joinCompetition
        case createCompetition
        case competitionDetails
        case userDetails
        case proUpgrade
        case about

        case none
    }

    @Published var shouldShowSheet = false
    var sheetToShow: HomepageSheet = .none
    var sheetContextData: Any?

    private let stateQueue = DispatchQueue(label: "HomepageSheetStateQueue")
    private var appProtocolCancellable: AnyCancellable?

    /// Order is important, it will decide the priority order for sheets to be shown
    private var homepageSheetState: [HomepageSheet: HomepageSheetState] = [
        .permissionPrompt: (shouldShow: false, contextData: nil),
        .joinCompetition: (shouldShow: false, contextData: nil),
        .createCompetition: (shouldShow: false, contextData: nil),
        .competitionDetails: (shouldShow: false, contextData: nil),
        .userDetails: (shouldShow: false, contextData: nil),
        .proUpgrade: (shouldShow: false, contextData: nil),
    ]

    init(appProtocolHandler: IAppProtocolHandler, healthKitManager: IHealthKitManager) {
        if healthKitManager.shouldPromptUser {
            updateState(sheet: .permissionPrompt, state: true)
        }

        appProtocolCancellable = appProtocolHandler.protocolDataPublisher.sink { [weak self] in
            if let protocolData = $0,
               protocolData is JoinCompetitionProtocolData {
                self?.updateState(sheet: .joinCompetition, state: true)
            }
        }
    }

    func updateState(sheet: HomepageSheet, state: Bool, contextData: Any? = nil) {
        stateQueue.sync {
            // Check if this update is changing anything
            let currentState = homepageSheetState[sheet]
            guard currentState?.shouldShow != state else {
                // If we haven't changed the state of the sheet, then no need to do an update
                // TODO: check if contextData has changed
                return
            }

            homepageSheetState[sheet] = (shouldShow: state, contextData: contextData)

            var foundSheetToShow = false
            for sheet in HomepageSheet.allCases {
                if homepageSheetState[sheet]?.shouldShow == true {
                    sheetToShow = sheet
                    sheetContextData = homepageSheetState[sheet]?.contextData
                    foundSheetToShow = true
                    break
                }
            }

            DispatchQueue.main.async {
                self.shouldShowSheet = foundSheetToShow
            }
        }
    }

    func dismissCurrentSheet() {
        updateState(sheet: sheetToShow, state: false)
    }
}
