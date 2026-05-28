//
//  HomeRedesignViewModelTests.swift
//  FitWithFriends
//
//  Covers the pure derivations introduced by the home redesign:
//   - HomepageViewModel.todayRingsHeadline
//   - HomepageViewModel.todayActivityStrip
//   - HomepageViewModel.firstName (via competition roster lookup)
//   - CompetitionOverviewViewModel.scoringChip per rule kind
//   - CompetitionOverviewViewModel.relationDescription
//

import SwiftUI
import XCTest
@testable import Fit_with_Friends

@MainActor
final class HomeRedesignViewModelTests: XCTestCase {
    private var mockCompetitionManager: MockCompetitionManager!
    private var mockAuthManager: MockAuthenticationManager!
    private var mockHealthKitManager: MockHealthKitManager!
    private var mockSubscriptionManager: MockSubscriptionManager!
    private var mockUserService: MockUserService!

    override func setUp() {
        super.setUp()
        mockCompetitionManager = MockCompetitionManager()
        mockCompetitionManager.return_competitionOverviews = [:]
        mockAuthManager = MockAuthenticationManager()
        mockHealthKitManager = MockHealthKitManager()
        mockSubscriptionManager = MockSubscriptionManager()
        mockUserService = MockUserService()
    }

    // MARK: - todayRingsHeadline

    func test_todayRingsHeadline_threeRingsClosed_celebrates() {
        let vm = makeHomepage()
        vm.todayActivitySummary = makeSummary(cal: 600, calGoal: 500, ex: 35, exGoal: 30, st: 12, stGoal: 12)

        XCTAssertTrue(vm.todayRingsHeadline.isCelebration)
        XCTAssertTrue(vm.todayRingsHeadline.prefix.contains("three"))
    }

    func test_todayRingsHeadline_twoRingsClosed_oneToGo() {
        let vm = makeHomepage()
        vm.todayActivitySummary = makeSummary(cal: 600, calGoal: 500, ex: 35, exGoal: 30, st: 4, stGoal: 12)

        XCTAssertTrue(vm.todayRingsHeadline.isCelebration)
        XCTAssertEqual(vm.todayRingsHeadline.prefix, "2 rings closed,")
    }

    func test_todayRingsHeadline_oneRingClosed_notCelebration() {
        let vm = makeHomepage()
        vm.todayActivitySummary = makeSummary(cal: 600, calGoal: 500, ex: 10, exGoal: 30, st: 4, stGoal: 12)

        XCTAssertFalse(vm.todayRingsHeadline.isCelebration)
    }

    func test_todayRingsHeadline_noRingsClosed_noneCelebration() {
        let vm = makeHomepage()
        vm.todayActivitySummary = makeSummary(cal: 100, calGoal: 500, ex: 5, exGoal: 30, st: 1, stGoal: 12)

        XCTAssertFalse(vm.todayRingsHeadline.isCelebration)
        XCTAssertTrue(vm.todayRingsHeadline.prefix.contains("No rings"))
    }

    func test_todayRingsHeadline_noSummary_safeFallback() {
        let vm = makeHomepage()
        vm.todayActivitySummary = nil

        XCTAssertFalse(vm.todayRingsHeadline.isCelebration)
        XCTAssertFalse(vm.todayRingsHeadline.prefix.isEmpty)
    }

    // MARK: - todayActivityStrip

    func test_todayActivityStrip_emptyWhenNoSummary() {
        let vm = makeHomepage()
        vm.todayActivitySummary = nil

        XCTAssertTrue(vm.todayActivityStrip.isEmpty)
    }

    func test_todayActivityStrip_hasRingItems() {
        let vm = makeHomepage()
        vm.todayActivitySummary = makeSummary(cal: 250, calGoal: 500, ex: 15, exGoal: 30, st: 6, stGoal: 12)

        let ids = vm.todayActivityStrip.map(\.id)
        XCTAssertEqual(ids, ["move", "exercise", "stand"])
    }

    // MARK: - firstName

    func test_firstName_pullsFromUserRowInCompetition() {
        mockAuthManager.loggedInUserId = "test_user"
        let competition = makeCompetitionWithUser(userId: "test_user", firstName: "Jordan")
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]

        let vm = makeHomepage()
        vm.currentCompetitions = [competition]

        XCTAssertEqual(vm.firstName, "Jordan")
    }

    func test_firstName_nilWhenUserNotInAnyCompetition() {
        mockAuthManager.loggedInUserId = "test_user"
        let vm = makeHomepage()
        vm.currentCompetitions = []

        XCTAssertNil(vm.firstName)
    }

    // MARK: - CompetitionOverviewViewModel.scoringChip

    func test_scoringChip_rings() {
        let chip = CompetitionOverviewViewModel.scoringChip(for: .default)
        XCTAssertEqual(chip.label, "Activity rings")
    }

    func test_scoringChip_workouts() {
        let chip = CompetitionOverviewViewModel.scoringChip(for: .workouts(metric: .duration, activityTypes: nil))
        XCTAssertEqual(chip.label, "Workouts")
    }

    func test_scoringChip_dailySteps() {
        let chip = CompetitionOverviewViewModel.scoringChip(for: .daily(metric: .steps))
        XCTAssertEqual(chip.label, "Daily steps")
    }

    func test_scoringChip_dailyDistance() {
        let chip = CompetitionOverviewViewModel.scoringChip(for: .daily(metric: .walkingRunningDistance))
        XCTAssertEqual(chip.label, "Daily distance")
    }

    // MARK: - CompetitionOverviewViewModel.relationDescription

    func test_relationDescription_pointsUnit() {
        let s = CompetitionOverviewViewModel.relationDescription(diff: 390, unit: .points)
        XCTAssertTrue(s.contains("390"))
        XCTAssertTrue(s.contains("pts"))
        XCTAssertTrue(s.contains("leads by"))
    }

    func test_relationDescription_stepsUnit() {
        let s = CompetitionOverviewViewModel.relationDescription(diff: 12_310, unit: .steps)
        XCTAssertTrue(s.contains("12,310"))
        XCTAssertTrue(s.contains("steps"))
    }

    // MARK: - CompetitionOverviewViewModel.ordinal + unitSuffix + unitColor

    func test_ordinal_correctForFirstThroughTwentyFirst() {
        XCTAssertEqual(CompetitionOverviewViewModel.ordinal(1), "1st")
        XCTAssertEqual(CompetitionOverviewViewModel.ordinal(2), "2nd")
        XCTAssertEqual(CompetitionOverviewViewModel.ordinal(3), "3rd")
        XCTAssertEqual(CompetitionOverviewViewModel.ordinal(4), "4th")
        XCTAssertEqual(CompetitionOverviewViewModel.ordinal(11), "11th")
        XCTAssertEqual(CompetitionOverviewViewModel.ordinal(21), "21st")
    }

    func test_unitSuffix_eachUnit() {
        XCTAssertEqual(CompetitionOverviewViewModel.unitSuffix(for: .points),  "pts today")
        XCTAssertEqual(CompetitionOverviewViewModel.unitSuffix(for: .steps),   "steps today")
        XCTAssertEqual(CompetitionOverviewViewModel.unitSuffix(for: .kcal),    "kcal today")
        XCTAssertEqual(CompetitionOverviewViewModel.unitSuffix(for: .minutes), "min today")
        XCTAssertEqual(CompetitionOverviewViewModel.unitSuffix(for: .meters),  "today")
    }

    func test_unitColor_distinctByRuleFamily() {
        // Just verify the three families produce three distinct colors — the exact
        // hex doesn't matter for the test, only that the view doesn't show all
        // three rule families with the same accent.
        let brand = CompetitionOverviewViewModel.unitColor(for: .default)
        let exercise = CompetitionOverviewViewModel.unitColor(for: .daily(metric: .steps))
        let move = CompetitionOverviewViewModel.unitColor(for: .workouts(metric: .duration, activityTypes: nil))
        XCTAssertNotEqual(brand, exercise)
        XCTAssertNotEqual(brand, move)
        XCTAssertNotEqual(exercise, move)
    }

    // MARK: - CompetitionOverviewViewModel integration (TodayDelta, LeaderStatus, medalColor, daysLeft)

    private func makeOverviewViewModel(rules: ScoringRules = .default,
                                        userId: String = "test_user",
                                        userTotal: Double = 422,
                                        userToday: Double = 235,
                                        leaderTotal: Double = 500,
                                        showAllDetails: Bool = false,
                                        end: Date = Date().addingTimeInterval(.xtDays(4)),
                                        start: Date = Date().addingTimeInterval(-.xtDays(8))) -> CompetitionOverviewViewModel {
        mockAuthManager.loggedInUserId = userId
        let leader = UserCompetitionPoints(userId: "alice", firstName: "Alice", lastName: "Chen", total: leaderTotal, today: 110)
        let me = UserCompetitionPoints(userId: userId, firstName: "You", lastName: "", total: userTotal, today: userToday)
        let trailing = UserCompetitionPoints(userId: "sam", firstName: "Sam", lastName: "Smith", total: 100, today: 5)
        let overview = CompetitionOverview(
            start: start, end: end,
            currentResults: [leader, me, trailing],
            scoringRules: rules
        )
        return CompetitionOverviewViewModel(
            authenticationManager: mockAuthManager,
            competitionManager: mockCompetitionManager,
            competitionOverview: overview,
            serverEnrivonmentManager: MockServerEnvironmentManager(),
            showAllDetails: showAllDetails
        )
    }

    func test_overview_userPosition_secondOrdinalAndSilverMedal() {
        let vm = makeOverviewViewModel(userTotal: 422, leaderTotal: 500)

        XCTAssertEqual(vm.userRank, 2)
        XCTAssertEqual(vm.userRankOrdinal, "2nd")
        XCTAssertEqual(vm.medalColor, Color("Silver"))
        XCTAssertEqual(vm.totalParticipants, 3)
    }

    func test_overview_userFirstPlace_goldMedalAndNoLeaderStatus() {
        let vm = makeOverviewViewModel(userTotal: 600, leaderTotal: 500)

        XCTAssertEqual(vm.userRank, 1)
        XCTAssertEqual(vm.medalColor, Color("Gold"))
        XCTAssertNil(vm.leaderStatus, "Leader status should be nil when user is the leader")
    }

    func test_overview_leaderStatus_setWhenBehind() {
        let vm = makeOverviewViewModel(userTotal: 100, leaderTotal: 490)

        XCTAssertNotNil(vm.leaderStatus)
        XCTAssertEqual(vm.leaderStatus?.name, "Alice")
        XCTAssertTrue(vm.leaderStatus?.relation.contains("leads by") == true)
        XCTAssertTrue(vm.leaderStatus?.relation.contains("390") == true)
    }

    func test_overview_todayDelta_inCompetitionUnit_forRings() {
        let vm = makeOverviewViewModel(rules: .default, userToday: 235)

        XCTAssertNotNil(vm.todayDelta)
        XCTAssertEqual(vm.todayDelta?.value, "+235")
        XCTAssertEqual(vm.todayDelta?.unit, "pts today")
    }

    func test_overview_todayDelta_inCompetitionUnit_forSteps() {
        let vm = makeOverviewViewModel(rules: .daily(metric: .steps), userToday: 8420)

        XCTAssertNotNil(vm.todayDelta)
        XCTAssertEqual(vm.todayDelta?.value, "+8,420")
        XCTAssertEqual(vm.todayDelta?.unit, "steps today")
    }

    func test_overview_daysLeft_clampedToZero_whenEnded() {
        let vm = makeOverviewViewModel(end: Date().addingTimeInterval(-86_400))
        XCTAssertEqual(vm.daysLeft, 0)
    }

    func test_overview_daysLeft_positiveWhenActive() {
        // 5 days from now — daysLeft uses `ceil(secondsLeft / 86_400)`, so the value
        // lands at 5 in the common case and 6 if there's any sub-second timing
        // variance between viewmodel construction and reading the property.
        let vm = makeOverviewViewModel(end: Date().addingTimeInterval(86_400 * 5))
        XCTAssertGreaterThanOrEqual(vm.daysLeft, 4)
        XCTAssertLessThanOrEqual(vm.daysLeft, 6)
    }

    func test_overview_scoringChipLabel_appliedAtInit() {
        let ringsVM = makeOverviewViewModel(rules: .default)
        XCTAssertEqual(ringsVM.scoringRuleChipLabel, "Activity rings")

        let stepsVM = makeOverviewViewModel(rules: .daily(metric: .steps))
        XCTAssertEqual(stepsVM.scoringRuleChipLabel, "Daily steps")
    }

    // MARK: - HomepageViewModel.greetingTitle / greetingSubtitle

    func test_greetingTitle_includesFirstNameWhenKnown() {
        mockAuthManager.loggedInUserId = "test_user"
        let comp = makeCompetitionWithUser(userId: "test_user", firstName: "Jordan")
        mockCompetitionManager.return_competitionOverviews = [comp.competitionId: comp]
        let vm = makeHomepage()
        vm.currentCompetitions = [comp]

        XCTAssertTrue(vm.greetingTitle.contains("Jordan"))
    }

    func test_greetingTitle_omitsNameWhenUnknown() {
        let vm = makeHomepage()
        vm.currentCompetitions = []

        // Greeting still has the salutation, just no name appended.
        XCTAssertFalse(vm.greetingTitle.contains(","))
    }

    func test_greetingSubtitle_isPrettyFormattedDate() {
        let vm = makeHomepage()
        let subtitle = vm.greetingSubtitle
        // Should contain the weekday and a 3-letter month abbreviation.
        XCTAssertFalse(subtitle.isEmpty)
        XCTAssertTrue(subtitle.contains(","))
    }

    // MARK: - Helpers

    private func makeHomepage() -> HomepageViewModel {
        HomepageViewModel(
            authenticationManager: mockAuthManager,
            competitionManager: mockCompetitionManager,
            healthKitManager: mockHealthKitManager,
            subscriptionManager: mockSubscriptionManager,
            userService: mockUserService
        )
    }

    private func makeSummary(cal: UInt, calGoal: UInt, ex: UInt, exGoal: UInt, st: UInt, stGoal: UInt) -> ActivitySummary {
        let dto = ActivitySummaryDTO(date: Date(),
                                     activeEnergyBurned: cal,
                                     activeEnergyBurnedGoal: calGoal,
                                     appleExerciseTime: ex,
                                     appleExerciseTimeGoal: exGoal,
                                     appleStandHours: st,
                                     appleStandHoursGoal: stGoal)
        return ActivitySummary(activitySummary: dto)
    }

    private func makeCompetitionWithUser(userId: String, firstName: String) -> CompetitionOverview {
        let me = UserCompetitionPoints(userId: userId, firstName: firstName, lastName: "Doe", total: 100, today: 50)
        let other = UserCompetitionPoints(userId: "other", firstName: "Alice", lastName: "Chen", total: 80, today: 30)
        return CompetitionOverview(
            start: Date().addingTimeInterval(-86400 * 2),
            end: Date().addingTimeInterval(86400 * 5),
            currentResults: [me, other]
        )
    }
}
