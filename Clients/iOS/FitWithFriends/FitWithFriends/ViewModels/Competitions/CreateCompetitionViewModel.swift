//
//  CreateCompetitionViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/27/21.
//

import Combine
import Foundation
import SwiftUI

@MainActor
public class CreateCompetitionViewModel: ObservableObject {
    public enum Step: Int {
        case templates
        case scoring
        case invite
    }

    /// Pro-tier template marker. Free users can tap a Pro template to preview the
    /// configuration; the Pro upgrade callout surfaces inside step 2.
    public enum TemplateTier { case free, pro }

    public struct Template: Identifiable {
        public let id: String
        public let title: String
        public let subtitle: String
        public let icon: String
        public let pillText: String?
        public let pillIsPro: Bool
        public let tier: TemplateTier
        public let durationDays: Int
        public let rule: ScoringRules
    }

    public static let templates: [Template] = [
        Template(
            id: "quick-weekend",
            title: "Quick Weekend",
            subtitle: "3 days · Activity rings · Default scoring",
            icon: "calendar",
            pillText: nil, pillIsPro: false, tier: .free,
            durationDays: 3,
            rule: .default
        ),
        Template(
            id: "friends-challenge",
            title: "Friends Challenge",
            subtitle: "1 week · Activity rings · The classic",
            icon: "person.3.fill",
            pillText: "Most picked", pillIsPro: false, tier: .free,
            durationDays: 7,
            rule: .default
        ),
        Template(
            id: "step-streak",
            title: "Step Streak",
            subtitle: "1 week · Daily totals · Steps",
            icon: "shoeprints.fill",
            pillText: "Pro", pillIsPro: true, tier: .pro,
            durationDays: 7,
            rule: .daily(metric: .steps)
        ),
        Template(
            id: "workout-wars",
            title: "Workout Wars",
            subtitle: "2 weeks · Tracked workouts · By minutes",
            icon: "figure.run",
            pillText: "Pro", pillIsPro: true, tier: .pro,
            durationDays: 14,
            rule: .workouts(metric: .duration, activityTypes: nil)
        ),
        Template(
            id: "monthly-showdown",
            title: "Monthly Showdown",
            subtitle: "30 days · Activity rings · With daily cap",
            icon: "rosette",
            pillText: nil, pillIsPro: false, tier: .free,
            durationDays: 30,
            rule: .rings(includedRings: Set(ScoringRing.allCases), minGoals: nil, dailyCap: 500)
        ),
    ]

    private let authenticationManager: IAuthenticationManager
    private let competitionManager: ICompetitionManager
    private let subscriptionManager: ISubscriptionManager
    private let homepageSheetViewModel: HomepageSheetViewModel
    private var cancellables = Set<AnyCancellable>()

    @Published var state: ViewOperationState = .notStarted
    @Published var currentStep: Step = .templates

    // Rule configuration — sourced from the chosen template, edited in step 2.
    @Published var competitionName: String = ""
    @Published var startDate: Date = Date().addingTimeInterval(.xtDays(1))
    @Published var endDate: Date = Date().addingTimeInterval(.xtDays(8))
    @Published var ruleKind: ScoringRules.Kind = .rings

    // Rings config
    @Published var includeCalories: Bool = true
    @Published var includeExercise: Bool = true
    @Published var includeStand: Bool = true
    @Published var enforceMinGoals: Bool = false
    @Published var minCalories: Int = 300
    @Published var minExercise: Int = 20
    @Published var minStand: Int = 8
    @Published var dailyCapEnabled: Bool = false
    @Published var dailyCap: Int = 600

    // Workouts config
    @Published var workoutMetric: WorkoutMetric = .duration
    @Published var selectedActivityTypes: Set<UInt> = []
    @Published var workoutMinDurationMinutes: Int = 10

    // Daily config
    @Published var dailyMetric: DailyMetric = .steps

    /// Name of the competition that was just created — the invite step uses this
    /// to look up the new competition from the manager's published overviews and
    /// fetch its share URL.
    @Published var lastCreatedCompetitionName: String?

    @Published var isUserPro: Bool

    init(authenticationManager: IAuthenticationManager,
         competitionManager: ICompetitionManager,
         subscriptionManager: ISubscriptionManager,
         homepageSheetViewModel: HomepageSheetViewModel) {
        self.authenticationManager = authenticationManager
        self.competitionManager = competitionManager
        self.subscriptionManager = subscriptionManager
        self.homepageSheetViewModel = homepageSheetViewModel
        self.isUserPro = subscriptionManager.isUserPro

        subscriptionManager.isUserProPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$isUserPro)
    }

    // MARK: - Step transitions

    func applyTemplate(_ template: Template) {
        competitionName = template.title
        startDate = Date().addingTimeInterval(.xtDays(1))
        endDate = startDate.addingTimeInterval(.xtDays(Double(template.durationDays)))
        applyRule(template.rule)
        withAnimation(.spring(duration: 0.35)) {
            currentStep = .scoring
        }
    }

    func startBlank() {
        competitionName = ""
        startDate = Date().addingTimeInterval(.xtDays(1))
        endDate = startDate.addingTimeInterval(.xtDays(7))
        applyRule(.default)
        withAnimation(.spring(duration: 0.35)) {
            currentStep = .scoring
        }
    }

    func goBack() {
        switch currentStep {
        case .templates:
            homepageSheetViewModel.updateState(sheet: .createCompetition, state: false)
        case .scoring:
            withAnimation(.spring(duration: 0.35)) { currentStep = .templates }
        case .invite:
            // No going back from invite — competition already exists. Dismiss instead.
            homepageSheetViewModel.updateState(sheet: .createCompetition, state: false)
        }
    }

    private func applyRule(_ rule: ScoringRules) {
        ruleKind = rule.kind
        switch rule {
        case let .rings(includedRings, minGoals, cap):
            includeCalories = includedRings.contains(.calories)
            includeExercise = includedRings.contains(.exercise)
            includeStand = includedRings.contains(.stand)
            if let minGoals, !minGoals.isEmpty {
                enforceMinGoals = true
                if let c = minGoals.calories { minCalories = c }
                if let e = minGoals.exerciseTime { minExercise = e }
                if let s = minGoals.standTime { minStand = s }
            } else {
                enforceMinGoals = false
            }
            if let cap {
                dailyCapEnabled = true
                dailyCap = cap
            } else {
                dailyCapEnabled = false
            }
        case let .workouts(metric, activityTypes):
            workoutMetric = metric
            selectedActivityTypes = Set(activityTypes ?? [])
        case let .daily(metric):
            dailyMetric = metric
        }
    }

    // MARK: - Rule assembly

    var includedRingCount: Int {
        [includeCalories, includeExercise, includeStand].filter { $0 }.count
    }

    /// True when the user's current rule config differs from the legacy default.
    /// Drives the Pro lock callout in step 2 (soft-gate — free users can still see
    /// the configuration UI, but can't submit a non-default rule).
    var requiresProUserMissing: Bool {
        guard !isUserPro else { return false }
        if ruleKind != .rings { return true }
        return includedRingCount < ScoringRing.allCases.count
            || enforceMinGoals
            || dailyCapEnabled
    }

    var canSubmit: Bool {
        if competitionName.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        if ruleKind == .rings && includedRingCount == 0 { return false }
        if requiresProUserMissing { return false }
        return true
    }

    func buildRule() -> ScoringRules {
        switch ruleKind {
        case .rings:
            var rings: Set<ScoringRing> = []
            if includeCalories { rings.insert(.calories) }
            if includeExercise { rings.insert(.exercise) }
            if includeStand { rings.insert(.stand) }

            var minGoals: RingMinGoals? = nil
            if enforceMinGoals {
                minGoals = RingMinGoals(
                    calories: includeCalories ? minCalories : nil,
                    exerciseTime: includeExercise ? minExercise : nil,
                    standTime: includeStand ? minStand : nil
                )
            }

            let cap: Int? = dailyCapEnabled ? dailyCap : nil
            let includedFull = rings == Set(ScoringRing.allCases)

            // Normalise to `.default` when nothing meaningful was customised.
            if includedFull && minGoals == nil && cap == nil {
                return .default
            }
            return .rings(includedRings: rings, minGoals: minGoals, dailyCap: cap)

        case .workouts:
            let types = selectedActivityTypes.isEmpty ? nil : Array(selectedActivityTypes).sorted()
            return .workouts(metric: workoutMetric, activityTypes: types)

        case .daily:
            return .daily(metric: dailyMetric)
        }
    }

    // MARK: - Create

    func createCompetition() {
        let name = competitionName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            state = .failed(errorMessage: "Please enter a competition name")
            return
        }

        let rules = buildRule()
        let start = startDate
        let end = endDate

        state = .inProgress

        Task.detached { [weak self] in
            guard let self = self else { return }

            do {
                try await self.competitionManager.createCompetition(startDate: start,
                                                                    endDate: end,
                                                                    competitionName: name,
                                                                    scoringRules: rules)
                await self.competitionManager.refreshCompetitionOverviews()
                await MainActor.run {
                    self.lastCreatedCompetitionName = name
                    self.state = .success
                    withAnimation(.spring(duration: 0.35)) {
                        self.currentStep = .invite
                    }
                }
            } catch {
                var errorMessage = error.localizedDescription
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

                await MainActor.run {
                    self.state = .failed(errorMessage: errorMessage)
                }
            }
        }
    }

}
