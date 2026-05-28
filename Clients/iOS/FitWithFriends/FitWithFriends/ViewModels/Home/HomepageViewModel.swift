//
//  HomepageViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import Combine
import Foundation
import HealthKit
import SwiftUI

@MainActor
public class HomepageViewModel: ObservableObject {
    private let authenticationManager: IAuthenticationManager
    private let competitionManager: ICompetitionManager
    private let healthKitManager: IHealthKitManager
    private let subscriptionManager: ISubscriptionManager
    private let userService: IUserService

    @Published var loadedActivitySummary: Bool
    @Published var todayActivitySummary: ActivitySummary?

    @Published var currentCompetitions: [CompetitionOverview]?
    @Published var publicCompetitions: [PublicCompetition]?
    @Published var isUserPro: Bool = false

    private var competitionLoadListener: AnyCancellable?
    private var publicCompetitionLoadListener: AnyCancellable?
    private var proStatusListener: AnyCancellable?

    init(authenticationManager: IAuthenticationManager,
         competitionManager: ICompetitionManager,
         healthKitManager: IHealthKitManager,
         subscriptionManager: ISubscriptionManager,
         userService: IUserService) {
        self.authenticationManager = authenticationManager
        self.competitionManager = competitionManager
        self.healthKitManager = healthKitManager
        self.subscriptionManager = subscriptionManager
        self.userService = userService

        loadedActivitySummary = false

        // Fire and forget the activity summary refresh
        Task.detached { await self.refreshTodayActivitySummary() }

        // Need to hold a reference to this, otherwise the sink callback will never be invoked
        competitionLoadListener = competitionManager.competitionOverviewsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.currentCompetitions = newValue.map { $0.value }
                    .sorted { $0 < $1 }
            }

        publicCompetitionLoadListener = competitionManager.publicCompetitionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.publicCompetitions = newValue
                    .filter { !$0.isUserMember && $0.endDate > Date() } // If the user is a member, it will be listed in currentCompetitions
            }

        proStatusListener = subscriptionManager.isUserProPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.isUserPro = newValue
            }

        // Check subscription status on init
        Task.detached { await subscriptionManager.checkSubscriptionStatus() }
    }

    func refreshData() async {
        let activitySummaryTask = Task { await self.refreshTodayActivitySummary() }
        let competitionTask = Task { await self.competitionManager.refreshCompetitionOverviews() }

        await activitySummaryTask.value
        await competitionTask.value
    }

    func logout() {
        authenticationManager.logout()
    }

    func deleteAccount() async -> Bool {
        do {
            try await userService.deleteAccount()
            authenticationManager.logout()
            return true
        } catch {
            Logger.traceError(message: "Failed to delete account", error: error)
            return false
        }
    }

    private func refreshTodayActivitySummary() async {
        let summary: ActivitySummary? = await withCheckedContinuation { continuation in
            healthKitManager.getCurrentActivitySummary { summary in
                continuation.resume(returning: summary)
            }
        }
        todayActivitySummary = summary
        loadedActivitySummary = true
    }

    // MARK: - Home redesign helpers

    /// The user's first name, looked up by matching `loggedInUserId` against the
    /// per-competition rosters. We don't persist the user model locally, so the
    /// rosters are the practical source of truth.
    var firstName: String? {
        guard let userId = authenticationManager.loggedInUserId,
              let competitions = currentCompetitions else { return nil }
        for comp in competitions {
            if let me = comp.currentResults.first(where: { $0.userId == userId }) {
                return me.firstName
            }
        }
        return nil
    }

    /// Full display name for the Settings account header. Derived the same way
    /// as `firstName` — first + last from the competition roster when the user
    /// is in one. Falls back to nil when no roster data is available.
    var displayName: String? {
        guard let userId = authenticationManager.loggedInUserId,
              let competitions = currentCompetitions else { return nil }
        for comp in competitions {
            if let me = comp.currentResults.first(where: { $0.userId == userId }) {
                let trimmed = me.displayName.trimmingCharacters(in: .whitespaces)
                return trimmed.isEmpty ? nil : trimmed
            }
        }
        return nil
    }

    /// One-line subtitle under the display name in the Settings account header.
    /// We don't have a `createdAt` field on User today, so fall back to the
    /// Apple Sign-In acknowledgement alone — the brief explicitly allows this.
    var memberSinceLabel: String {
        return "Signed in with Apple"
    }

    /// e.g. "Good morning, Jordan" — falls back to "Good morning" when the name
    /// isn't known yet (first launch, no competitions joined).
    var greetingTitle: String {
        let salutation = Self.salutation(for: Date())
        if let firstName, !firstName.isEmpty {
            return "\(salutation), \(firstName)"
        }
        return salutation
    }

    /// e.g. "Wednesday, Apr 15"
    var greetingSubtitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    /// Sentence headline for the today panel — composed of a prefix fragment and
    /// an italicised accent fragment (so the view can render the second piece in
    /// New York italic + accent color).
    struct TodayRingsHeadline {
        let prefix: String
        let accent: String
        let isCelebration: Bool   // true when ≥ 2 rings closed today
    }

    var todayRingsHeadline: TodayRingsHeadline {
        guard let summary = todayActivitySummary else {
            return TodayRingsHeadline(prefix: "Let's start moving", accent: "", isCelebration: false)
        }

        let closed = Self.ringsClosed(summary)
        switch closed {
        case 3:
            return TodayRingsHeadline(prefix: "All three rings closed.", accent: "Nice.", isCelebration: true)
        case 2:
            return TodayRingsHeadline(prefix: "2 rings closed,", accent: "one to go.", isCelebration: true)
        case 1:
            return TodayRingsHeadline(prefix: "1 ring closed,", accent: "keep pushing.", isCelebration: false)
        default:
            return TodayRingsHeadline(prefix: "No rings closed yet.", accent: "Today's still young.", isCelebration: false)
        }
    }

    /// Five cards for the horizontal activity strip on the home screen.
    /// Each card is universal — same value regardless of any per-competition scoring rule.
    struct ActivityStripItem: Identifiable {
        let id: String                  // stable key for ForEach
        let label: String
        let value: String
        let goalDescription: String?    // "of 500 cal", "of 30 min", etc.
        let progress: Double            // 0..1, drives the small bar
        let tintHex: String             // hex color string the view turns into Color(hex:)
    }

    var todayActivityStrip: [ActivityStripItem] {
        guard let summary = todayActivitySummary else { return [] }

        let movePct = summary.activeCaloriesGoal > 0
            ? min(1.0, Double(summary.activeCaloriesBurned) / Double(summary.activeCaloriesGoal))
            : 0
        let exercisePct = summary.exerciseTimeGoal > 0
            ? min(1.0, Double(summary.exerciseTime) / Double(summary.exerciseTimeGoal))
            : 0
        let standPct = summary.standTimeGoal > 0
            ? min(1.0, Double(summary.standTime) / Double(summary.standTimeGoal))
            : 0

        var items: [ActivityStripItem] = [
            ActivityStripItem(
                id: "move",
                label: "Move",
                value: "\(summary.activeCaloriesBurned)",
                goalDescription: "of \(summary.activeCaloriesGoal) cal",
                progress: movePct,
                tintHex: "FA114F"
            ),
            ActivityStripItem(
                id: "exercise",
                label: "Exercise",
                value: "\(summary.exerciseTime)",
                goalDescription: "of \(summary.exerciseTimeGoal) min",
                progress: exercisePct,
                tintHex: "92E82A"
            ),
            ActivityStripItem(
                id: "stand",
                label: "Stand",
                value: "\(summary.standTime)",
                goalDescription: "of \(summary.standTimeGoal) hr",
                progress: standPct,
                tintHex: "1EEAEF"
            ),
        ]

        if let steps = summary.stepCount, steps > 0 {
            items.append(ActivityStripItem(
                id: "steps",
                label: "Steps",
                value: Self.formatThousands(Int(steps)),
                goalDescription: "today",
                progress: 0,
                tintHex: "2A3F7A"
            ))
        }

        return items
    }

    // MARK: - Helpers

    private static func salutation(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 0..<5: return "Still up"
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good evening"
        }
    }

    private static func ringsClosed(_ summary: ActivitySummary) -> Int {
        var count = 0
        if summary.activeCaloriesGoal > 0, summary.activeCaloriesBurned >= summary.activeCaloriesGoal { count += 1 }
        if summary.exerciseTimeGoal > 0, summary.exerciseTime >= summary.exerciseTimeGoal { count += 1 }
        if summary.standTimeGoal > 0, summary.standTime >= summary.standTimeGoal { count += 1 }
        return count
    }

    private static func formatThousands(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
