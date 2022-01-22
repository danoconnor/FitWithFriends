//
//  HomePageSheetViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/6/21.
//

import Foundation

class HomepageSheetViewModel: ObservableObject {
    // Order is important - sheets listed first will be given precedence over those listed later
    enum HomepageSheet: String, CaseIterable {
        case permissionPrompt
        case createCompetition

        case none
    }

    @Published var shouldShowSheet = false
    var sheetToShow: HomepageSheet = .none

    private let stateQueue = DispatchQueue(label: "HomepageSheetStateQueue")

    private var homepageSheetState: [HomepageSheet: Bool] = [
        .permissionPrompt: false,
        .createCompetition: false
    ]

    init(healthKitManager: HealthKitManager) {
        if healthKitManager.shouldPromptUser {
            updateState(sheet: .permissionPrompt, state: true)
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
