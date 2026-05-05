//
//  CompetitionsPagerViewModel.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import Combine
import Foundation

/// Decides what the root Watch screen shows and exposes an ordered list of pages
/// for the pager. Pure presentation logic — no SwiftUI in here so it's unit-testable.
class CompetitionsPagerViewModel: ObservableObject {
    enum DisplayState: Equatable {
        case loading
        case signedOut
        case noCompetitions
        case competitions([CompetitionOverview])
    }

    @Published private(set) var displayState: DisplayState = .loading

    private let authenticationManager: IAuthenticationManager
    private let competitionManager: ICompetitionManager
    private var cancellables = Set<AnyCancellable>()
    private var hasReceivedData = false

    init(authenticationManager: IAuthenticationManager,
         competitionManager: ICompetitionManager) {
        self.authenticationManager = authenticationManager
        self.competitionManager = competitionManager

        authenticationManager.loginStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.recomputeDisplayState(loginState: state)
            }
            .store(in: &cancellables)

        competitionManager.competitionOverviewsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.hasReceivedData = true
                self?.recomputeDisplayState(loginState: authenticationManager.loginState)
            }
            .store(in: &cancellables)
    }

    /// Exposed for tests and for triggering a recompute after external state changes.
    func recomputeDisplayState(loginState: LoginState) {
        switch loginState {
        case .notLoggedIn:
            displayState = .signedOut
        case .inProgress:
            displayState = .loading
        case .needUserInfo:
            // On the Watch there is no first-launch flow. Treat this as signed-out.
            displayState = .signedOut
        case .loggedIn:
            if !hasReceivedData {
                displayState = .loading
                return
            }

            let sorted = Self.sortCompetitionsForDisplay(Array(competitionManager.competitionOverviews.values))
            if sorted.isEmpty {
                displayState = .noCompetitions
            } else {
                displayState = .competitions(sorted)
            }
        }
    }

    /// Ordering rule: active competitions first (most-ending-soon), then upcoming
    /// (most-starting-soon), then recently ended. Reuses CompetitionOverview's
    /// Comparable so the Watch never disagrees with the phone on ordering.
    static func sortCompetitionsForDisplay(_ overviews: [CompetitionOverview]) -> [CompetitionOverview] {
        return overviews.sorted()
    }
}
