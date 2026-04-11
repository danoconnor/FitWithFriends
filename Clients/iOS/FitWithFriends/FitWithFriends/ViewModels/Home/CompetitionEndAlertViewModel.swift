//
//  CompetitionEndAlertViewModel.swift
//  FitWithFriends
//

import Combine
import Foundation

@MainActor
class CompetitionEndAlertViewModel: ObservableObject {
    @Published var currentAlertCompetition: CompetitionOverview?
    @Published var shouldShowConfetti: Bool = false

    private var pendingCompetitions: [CompetitionOverview] = []
    private var cancellable: AnyCancellable?
    private let authenticationManager: IAuthenticationManager
    private let userDefaults: UserDefaults

    init(competitionManager: ICompetitionManager,
         authenticationManager: IAuthenticationManager,
         userDefaults: UserDefaults = .standard) {
        self.authenticationManager = authenticationManager
        self.userDefaults = userDefaults

        cancellable = competitionManager.competitionOverviewsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] overviews in
                self?.processNewOverviews(overviews)
            }
    }

    private func processNewOverviews(_ overviews: [UUID: CompetitionOverview]) {
        guard currentAlertCompetition == nil else { return }

        let unseen = overviews.values
            .filter { $0.competitionState == .archived }
            .filter { !userDefaults.bool(forKey: seenKey(for: $0.competitionId)) }
            .sorted { $0.endDate > $1.endDate }

        pendingCompetitions.append(contentsOf: unseen)
        showNextIfNeeded()
    }

    func alertDismissed() {
        if let current = currentAlertCompetition {
            userDefaults.set(true, forKey: seenKey(for: current.competitionId))
        }
        shouldShowConfetti = false
        currentAlertCompetition = nil
        showNextIfNeeded()
    }

    private func showNextIfNeeded() {
        guard currentAlertCompetition == nil, let next = pendingCompetitions.first else { return }
        pendingCompetitions.removeFirst()
        let willShowConfetti = (userPosition(in: next) ?? Int.max) <= 3
        if willShowConfetti {
            // Start confetti first so particles are already in motion when the
            // alert's dim overlay appears, keeping them visible to the user.
            shouldShowConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.currentAlertCompetition = next
            }
        } else {
            currentAlertCompetition = next
        }
    }

    var alertTitle: String {
        guard let competition = currentAlertCompetition else { return "" }
        return "\(competition.competitionName) has ended!"
    }

    var alertMessage: String {
        guard let competition = currentAlertCompetition else { return "" }
        if let position = userPosition(in: competition) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .ordinal
            let ordinal = formatter.string(from: NSNumber(value: position)) ?? "\(position)"
            return "You finished in \(ordinal) place."
        }
        return "The competition has ended."
    }

    private func userPosition(in competition: CompetitionOverview) -> Int? {
        guard let userId = authenticationManager.loggedInUserId else { return nil }
        let sorted = competition.currentResults.sorted()
        guard let idx = sorted.firstIndex(where: { $0.userId == userId }) else { return nil }
        return idx + 1
    }

    private func seenKey(for competitionId: UUID) -> String {
        "hasSeenCompetitionEndAlert_\(competitionId.uuidString)"
    }
}
