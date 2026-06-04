//
//  CompetitionEndAlertViewModelTests.swift
//  FitWithFriends
//

import Combine
import SwiftUI
import XCTest
@testable import Fit_with_Friends

@MainActor
final class CompetitionEndAlertViewModelTests: XCTestCase {
    private var mockCompetitionManager: MockCompetitionManager!
    private var mockAuthManager: MockAuthenticationManager!
    private var testUserDefaults: UserDefaults!
    private var testSuiteName: String!

    override func setUp() {
        super.setUp()
        mockCompetitionManager = MockCompetitionManager()
        mockAuthManager = MockAuthenticationManager()
        testSuiteName = UUID().uuidString
        testUserDefaults = UserDefaults(suiteName: testSuiteName)!
        // Start with empty overviews so the default mock data doesn't interfere
        mockCompetitionManager.return_competitionOverviews = [:]
    }

    override func tearDown() {
        testUserDefaults.removeSuite(named: testSuiteName)
        testUserDefaults = nil
        mockCompetitionManager = nil
        mockAuthManager = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeVM() -> CompetitionEndAlertViewModel {
        mockAuthManager.loggedInUserId = "test_user"
        return CompetitionEndAlertViewModel(
            competitionManager: mockCompetitionManager,
            authenticationManager: mockAuthManager,
            userDefaults: testUserDefaults
        )
    }

    /// Makes a CompetitionOverview where the test user is at `userPosition` (1-indexed).
    /// Other users fill the remaining slots with descending points so sorted order is deterministic.
    private func makeArchivedCompetition(id: UUID = UUID(),
                                          name: String = "Test Competition",
                                          userPosition: Int,
                                          totalUsers: Int = 5) -> CompetitionOverview {
        var results: [UserCompetitionPoints] = []
        for i in 0..<totalUsers {
            let isTestUser = (i == userPosition - 1)
            let points = Double(totalUsers - i) * 100
            results.append(UserCompetitionPoints(
                userId: isTestUser ? "test_user" : "other_user_\(i)",
                firstName: "User", lastName: "\(i)",
                total: points, today: 0
            ))
        }
        return CompetitionOverview(
            id: id, name: name,
            start: Date(timeIntervalSinceNow: -86400 * 8),
            end: Date(timeIntervalSinceNow: -86400),
            currentResults: results,
            competitionState: .archived
        )
    }

    private func makeCompetition(state: CompetitionState) -> CompetitionOverview {
        let result = UserCompetitionPoints(userId: "test_user", firstName: "Test", lastName: "User", total: 100, today: 0)
        return CompetitionOverview(
            id: UUID(), name: "Competition",
            start: Date(timeIntervalSinceNow: -86400 * 8),
            end: Date(timeIntervalSinceNow: -86400),
            currentResults: [result],
            competitionState: state
        )
    }

    /// Polls `condition` every 50 ms until it returns `true` or `timeout` seconds elapse.
    /// Always waits at least one poll interval before checking, so async work (Combine pipeline
    /// delivery, the 0.8 s confetti delay, etc.) has time to execute.
    private func waitUntil(_ condition: @autoclosure () -> Bool, timeout: TimeInterval = 2.0) async {
        let pollIntervalNs: UInt64 = 50_000_000 // 50 ms
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            try? await Task.sleep(nanoseconds: pollIntervalNs)
        } while !condition() && Date() < deadline
    }

    // MARK: - Alert Trigger Tests

    func test_archivedCompetition_showsAlert() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertNotNil(vm.currentAlertCompetition)
    }

    func test_archivedCompetition_marksNotificationsSeen() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)
        // The mark-seen call is fire-and-forget in a detached Task
        await waitUntil(mockCompetitionManager.markCompetitionNotificationsSeenCallCount > 0)

        XCTAssertEqual(mockCompetitionManager.markCompetitionNotificationsSeenCallCount, 1)
        XCTAssertEqual(mockCompetitionManager.param_markCompetitionNotificationsSeen_competitionId, competition.competitionId)
    }

    func test_nonArchivedCompetition_doesNotMarkNotificationsSeen() async {
        let vm = makeVM()
        let competition = makeCompetition(state: .processingResults)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.shouldShowConfetti == false)

        XCTAssertEqual(mockCompetitionManager.markCompetitionNotificationsSeenCallCount, 0)
    }

    func test_notStartedOrActiveCompetition_doesNotShowAlert() async {
        let vm = makeVM()
        let competition = makeCompetition(state: .notStartedOrActive)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        // Poll until the Combine pipeline has had a chance to deliver; no async delay applies for
        // non-archived state, so we wait for shouldShowConfetti to remain false (confirming delivery).
        await waitUntil(vm.shouldShowConfetti == false)

        XCTAssertNil(vm.currentAlertCompetition)
    }

    func test_processingResultsCompetition_doesNotShowAlert() async {
        let vm = makeVM()
        let competition = makeCompetition(state: .processingResults)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.shouldShowConfetti == false)

        XCTAssertNil(vm.currentAlertCompetition)
    }

    func test_alreadySeenCompetition_doesNotShowAlert() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1)
        testUserDefaults.set(true, forKey: "hasSeenCompetitionEndAlert_\(competition.competitionId.uuidString)")

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.shouldShowConfetti == false)

        XCTAssertNil(vm.currentAlertCompetition)
    }

    // MARK: - Confetti Tests

    func test_userInFirstPlace_showsConfetti() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.shouldShowConfetti)

        XCTAssertTrue(vm.shouldShowConfetti)
    }

    func test_userInThirdPlace_noConfetti() async {
        // The podium sheet celebrates a win only — confetti no longer fires for podium
        // finishes (2nd/3rd), only for 1st.
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 3)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertFalse(vm.shouldShowConfetti)
    }

    func test_userInSecondPlace_noConfetti() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 2)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertFalse(vm.shouldShowConfetti)
    }

    func test_userInFourthPlace_noConfetti() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 4)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertFalse(vm.shouldShowConfetti)
    }

    func test_userNotInResults_noConfetti_fallbackMessage() async {
        mockAuthManager.loggedInUserId = "unknown_user"
        let vm = CompetitionEndAlertViewModel(
            competitionManager: mockCompetitionManager,
            authenticationManager: mockAuthManager,
            userDefaults: testUserDefaults
        )
        let competition = makeArchivedCompetition(userPosition: 1) // "test_user" is in results, but VM uses "unknown_user"

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertFalse(vm.shouldShowConfetti)
        XCTAssertEqual(vm.alertMessage, "The competition has ended.")
    }

    // MARK: - Alert Message Tests

    func test_alertMessage_firstPlace_correctOrdinal() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertTrue(vm.alertMessage.contains("1st"), "Expected '1st' in '\(vm.alertMessage)'")
    }

    func test_alertMessage_secondPlace_correctOrdinal() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 2)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertTrue(vm.alertMessage.contains("2nd"), "Expected '2nd' in '\(vm.alertMessage)'")
    }

    func test_alertMessage_thirdPlace_correctOrdinal() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 3)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertTrue(vm.alertMessage.contains("3rd"), "Expected '3rd' in '\(vm.alertMessage)'")
    }

    func test_alertMessage_fourthPlace_correctOrdinal() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 4)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertTrue(vm.alertMessage.contains("4th"), "Expected '4th' in '\(vm.alertMessage)'")
    }

    func test_alertTitle_containsCompetitionName() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1)
        // The makeArchivedCompetition helper uses name: "Test Competition" by default

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertTrue(vm.alertTitle.contains("Test Competition"))
        XCTAssertTrue(vm.alertTitle.contains("ended"))
    }

    // MARK: - Dismiss Tests

    func test_alertDismissed_writesUserDefaultsKey() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        let competitionId = competition.competitionId
        vm.alertDismissed()

        XCTAssertTrue(testUserDefaults.bool(forKey: "hasSeenCompetitionEndAlert_\(competitionId.uuidString)"))
    }

    func test_alertDismissed_clearsCurrentAlert() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        vm.alertDismissed()
        XCTAssertNil(vm.currentAlertCompetition)
    }

    func test_alertDismissed_clearsConfetti() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.shouldShowConfetti)
        XCTAssertTrue(vm.shouldShowConfetti)

        vm.alertDismissed()
        XCTAssertFalse(vm.shouldShowConfetti)
    }

    // MARK: - Queue Tests

    func test_multipleArchivedCompetitions_shownSerially() async {
        let vm = makeVM()
        let comp1 = makeArchivedCompetition(id: UUID(), name: "First", userPosition: 1, totalUsers: 5)
        let comp2 = makeArchivedCompetition(id: UUID(), name: "Second", userPosition: 2, totalUsers: 5)
        let comp3 = makeArchivedCompetition(id: UUID(), name: "Third", userPosition: 3, totalUsers: 5)

        mockCompetitionManager.return_competitionOverviews = [
            comp1.competitionId: comp1,
            comp2.competitionId: comp2,
            comp3.competitionId: comp3
        ]

        // One alert is shown (which one depends on endDate sorting — all have same endDate here,
        // so we just verify one is shown and subsequent dismissals drain the queue)
        await waitUntil(vm.currentAlertCompetition != nil)
        XCTAssertNotNil(vm.currentAlertCompetition)
        vm.alertDismissed()

        await waitUntil(vm.currentAlertCompetition != nil)
        XCTAssertNotNil(vm.currentAlertCompetition)
        vm.alertDismissed()

        await waitUntil(vm.currentAlertCompetition != nil)
        XCTAssertNotNil(vm.currentAlertCompetition)
        vm.alertDismissed()

        XCTAssertNil(vm.currentAlertCompetition)
    }

    // MARK: - EndVariant tests (Phase 5 redesign)

    func test_endVariant_firstPlace_won() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1, totalUsers: 8)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertEqual(vm.endVariant, .won)
    }

    func test_endVariant_secondPlace_silver() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 2, totalUsers: 8)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertEqual(vm.endVariant, .silver)
    }

    func test_endVariant_thirdPlace_bronze() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 3, totalUsers: 8)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertEqual(vm.endVariant, .bronze)
    }

    func test_endVariant_midPack() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 5, totalUsers: 8)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertEqual(vm.endVariant, .midPack)
    }

    func test_endVariant_lastPlace() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 8, totalUsers: 8)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertEqual(vm.endVariant, .last)
    }

    func test_userPositionOrdinal_correctFormat() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 2, totalUsers: 5)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertEqual(vm.userPositionOrdinal, "2nd")
    }

    // MARK: - Derived stats (daily summaries)

    /// Seeds daily summaries on the mock and triggers the loader. The VM fetches
    /// summaries inside `showNextIfNeeded` via an unawaited Task, so we poll until
    /// it lands.
    private func seedSummariesAndShow(_ summaries: [DailySummary], userPosition: Int = 5, totalUsers: Int = 8) async -> CompetitionEndAlertViewModel {
        let details = UserCompetitionDailyDetails(
            userId: "test_user",
            competitionId: UUID(),
            dailySummaries: summaries)
        mockCompetitionManager.return_getUserCompetitionDetails = details

        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: userPosition, totalUsers: totalUsers)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.dailySummaries.count == summaries.count)
        return vm
    }

    func test_daysClosedAllRings_countsOnlyDaysWithAllRings() async {
        let summaries = [
            DailySummary(caloriesBurned: 500, caloriesGoal: 400,
                         exerciseTime: 40, exerciseTimeGoal: 30,
                         standTime: 12, standTimeGoal: 12, points: 300),
            DailySummary(caloriesBurned: 200, caloriesGoal: 400,
                         exerciseTime: 40, exerciseTimeGoal: 30,
                         standTime: 12, standTimeGoal: 12, points: 220),
            DailySummary(caloriesBurned: 500, caloriesGoal: 400,
                         exerciseTime: 40, exerciseTimeGoal: 30,
                         standTime: 12, standTimeGoal: 12, points: 300),
        ]
        let vm = await seedSummariesAndShow(summaries)

        XCTAssertEqual(vm.daysClosedAllRings, 2)
    }

    func test_moveRingStreak_findsLongestConsecutiveRun() async {
        let day = TimeInterval(86_400)
        let summaries = [
            // chronological: closed, closed, missed, closed, closed, closed → streak 3
            DailySummary(date: Date().addingTimeInterval(-day * 5),
                         caloriesBurned: 500, caloriesGoal: 400, points: 100),
            DailySummary(date: Date().addingTimeInterval(-day * 4),
                         caloriesBurned: 500, caloriesGoal: 400, points: 100),
            DailySummary(date: Date().addingTimeInterval(-day * 3),
                         caloriesBurned: 200, caloriesGoal: 400, points: 50),
            DailySummary(date: Date().addingTimeInterval(-day * 2),
                         caloriesBurned: 500, caloriesGoal: 400, points: 100),
            DailySummary(date: Date().addingTimeInterval(-day),
                         caloriesBurned: 500, caloriesGoal: 400, points: 100),
            DailySummary(date: Date(),
                         caloriesBurned: 500, caloriesGoal: 400, points: 100),
        ]
        let vm = await seedSummariesAndShow(summaries)

        XCTAssertEqual(vm.moveRingStreak, 3)
    }

    func test_moveRingStreak_zeroWhenNoClosures() async {
        let summaries = [
            DailySummary(caloriesBurned: 100, caloriesGoal: 400, points: 50),
            DailySummary(caloriesBurned: 200, caloriesGoal: 400, points: 80),
        ]
        let vm = await seedSummariesAndShow(summaries)

        XCTAssertEqual(vm.moveRingStreak, 0)
    }

    func test_bestDay_returnsHighestPointsDay() async {
        let topDate = Date().addingTimeInterval(-86_400)
        let summaries = [
            DailySummary(date: Date(), points: 100),
            DailySummary(date: topDate, points: 400),
            DailySummary(date: Date().addingTimeInterval(-86_400 * 2), points: 250),
        ]
        let vm = await seedSummariesAndShow(summaries)

        XCTAssertNotNil(vm.bestDay)
        XCTAssertEqual(vm.bestDay?.date, topDate)
        XCTAssertEqual(vm.bestDay?.points, 400)
    }

    func test_bestDay_nilWhenNoSummaries() async {
        let vm = makeVM()
        XCTAssertNil(vm.bestDay)
    }

    func test_winner_returnsFirstPlaceFinisher() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 3, totalUsers: 5)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        let winner = vm.winner
        XCTAssertNotNil(winner)
        // makeArchivedCompetition assigns descending points by index (totalUsers - i) * 100,
        // so user_0 has the highest score.
        XCTAssertEqual(winner?.userId, "other_user_0")
    }

    func test_gapToFirst_formatsPointsBehindWinner() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 2, totalUsers: 5)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        // Winner has (5-0)*100=500, position 2 has (5-1)*100=400 → gap is 100
        XCTAssertEqual(vm.gapToFirst, "100 pts")
    }

    func test_gapToFirst_nilWhenUserIsWinner() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1, totalUsers: 5)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertNil(vm.gapToFirst)
    }

    func test_totalDisplay_fallsBackToCompetitionRowWhenSummariesEmpty() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 2, totalUsers: 5)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        // No summaries seeded → loader will error from the mock and dailySummaries stays empty.
        // The fallback path reads from currentResults: user at position 2 has 400 points.
        XCTAssertEqual(vm.totalDisplay, "400 pts")
    }

    func test_totalDisplay_dashWhenNoData() async {
        mockAuthManager.loggedInUserId = "unknown_user"
        let vm = CompetitionEndAlertViewModel(
            competitionManager: mockCompetitionManager,
            authenticationManager: mockAuthManager,
            userDefaults: testUserDefaults
        )
        let competition = makeArchivedCompetition(userPosition: 1, totalUsers: 5)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertEqual(vm.totalDisplay, "—")
    }

    func test_publisherUpdate_whileAlertShowing_doesNotOverwrite() async {
        let vm = makeVM()
        let comp1 = makeArchivedCompetition(id: UUID(), name: "First", userPosition: 1)

        mockCompetitionManager.return_competitionOverviews = [comp1.competitionId: comp1]
        await waitUntil(vm.currentAlertCompetition != nil)
        XCTAssertNotNil(vm.currentAlertCompetition)
        let firstCompetitionId = vm.currentAlertCompetition?.competitionId

        // Emit a new value while the first alert is still showing
        let comp2 = makeArchivedCompetition(id: UUID(), name: "Second", userPosition: 2)
        mockCompetitionManager.return_competitionOverviews = [
            comp1.competitionId: comp1,
            comp2.competitionId: comp2
        ]
        // Poll until the pipeline has delivered the second update (at which point the VM will
        // have returned early, leaving comp1 as the active alert).
        await waitUntil(vm.currentAlertCompetition?.competitionId == firstCompetitionId)

        // Current alert should not have changed
        XCTAssertEqual(vm.currentAlertCompetition?.competitionId, firstCompetitionId)
    }

    // MARK: - Podium sheet (Direction B) presentation model

    func test_endOutcome_firstPlace_won() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertEqual(vm.endOutcome, .won)
    }

    func test_endOutcome_midPack_mid() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 2, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        // 2nd of 6 is neither first nor last → mid.
        XCTAssertEqual(vm.endOutcome, .mid)
    }

    func test_endOutcome_lastPlace_last() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 6, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertEqual(vm.endOutcome, .last)
    }

    func test_userPlacementAndMemberCount() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 4, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertEqual(vm.userPlacement, 4)
        XCTAssertEqual(vm.memberCount, 6)
    }

    func test_isUserOnPodium_trueForTopThree() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 3, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertTrue(vm.isUserOnPodium)
    }

    func test_isUserOnPodium_falseForMidPack() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 4, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertFalse(vm.isUserOnPodium)
    }

    func test_headlineAccent_perOutcome() async {
        let vm = makeVM()

        let won = makeArchivedCompetition(id: UUID(), name: "A", userPosition: 1, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [won.competitionId: won]
        await waitUntil(vm.currentAlertCompetition != nil)
        XCTAssertEqual(vm.headlineAccent, "You won.")
        vm.dismissCurrent()

        let mid = makeArchivedCompetition(id: UUID(), name: "B", userPosition: 3, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [mid.competitionId: mid]
        await waitUntil(vm.currentAlertCompetition != nil)
        XCTAssertEqual(vm.headlineAccent, "Strong showing.")
        vm.dismissCurrent()

        let last = makeArchivedCompetition(id: UUID(), name: "C", userPosition: 6, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [last.competitionId: last]
        await waitUntil(vm.currentAlertCompetition != nil)
        XCTAssertEqual(vm.headlineAccent, "Every day counts.")
    }

    func test_outcomeSubline_lastIncludesDayCount() async {
        let vm = makeVM()
        // Competition spans 7 days (start -8d, end -1d).
        let competition = makeArchivedCompetition(userPosition: 6, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertTrue(vm.outcomeSubline.contains("7 days"), "Expected day count in '\(vm.outcomeSubline)'")
        XCTAssertTrue(vm.outcomeSubline.contains("never quit"))
    }

    func test_podiumEntries_returnsTopThreeInOrder() async {
        let vm = makeVM()
        // User is 4th, so they should NOT appear in the podium (top 3 only).
        let competition = makeArchivedCompetition(userPosition: 4, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        let podium = vm.podiumEntries
        XCTAssertEqual(podium.count, 3)
        XCTAssertEqual(podium.map { $0.position }, [1, 2, 3])
        // Descending points: (6-0)*100=600, 500, 400.
        XCTAssertEqual(podium.map { $0.points }, [600, 500, 400])
        XCTAssertFalse(podium.contains { $0.isCurrentUser })
    }

    func test_podiumEntries_flagsCurrentUserWhenOnPodium() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        let podium = vm.podiumEntries
        XCTAssertEqual(podium.first(where: { $0.isCurrentUser })?.position, 1)
    }

    func test_userScoreValue_formatsPointsWithoutSuffix() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 2, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        // Position 2 of 6 → (6-1)*100 = 500, no unit suffix.
        XCTAssertEqual(vm.userScoreValue, "500")
    }

    func test_unitTagText_defaultsToPTS() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 1, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        XCTAssertEqual(vm.unitTagText, "PTS")
    }

    // MARK: - Share

    func test_shareText_win_includesTrophyAndPlacement() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(name: "Step Showdown", userPosition: 1, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        let text = vm.shareText
        XCTAssertTrue(text.contains("🏆"), "Expected trophy in '\(text)'")
        XCTAssertTrue(text.contains("1st of 6"))
        XCTAssertTrue(text.contains("Step Showdown"))
        XCTAssertTrue(text.contains("Fit with Friends"))
    }

    func test_shareText_midPack_noTrophy() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(name: "Step Showdown", userPosition: 3, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        let text = vm.shareText
        XCTAssertFalse(text.contains("🏆"))
        XCTAssertTrue(text.contains("3rd of 6"))
    }

    func test_shareText_last_includesDayCount() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(name: "Step Showdown", userPosition: 6, totalUsers: 6)
        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.currentAlertCompetition != nil)

        let text = vm.shareText
        XCTAssertTrue(text.contains("7 days"), "Expected day count in '\(text)'")
        XCTAssertTrue(text.contains("never quit"))
    }

    func test_appStoreURL_isValid() {
        XCTAssertNotNil(URL(string: CompetitionEndAlertViewModel.appStoreURL))
        XCTAssertTrue(CompetitionEndAlertViewModel.appStoreURL.contains("apps.apple.com"))
    }

    func test_shareCard_rendersNonNilImage() {
        // Smoke test: the share card builds and rasterizes via ImageRenderer for each outcome.
        let entries = [
            CompetitionEndAlertViewModel.PodiumEntry(position: 1, firstName: "You", displayName: "You", points: 612, isCurrentUser: true),
            CompetitionEndAlertViewModel.PodiumEntry(position: 2, firstName: "Alice", displayName: "Alice Chen", points: 580, isCurrentUser: false),
            CompetitionEndAlertViewModel.PodiumEntry(position: 3, firstName: "Marcus", displayName: "Marcus Lee", points: 512, isCurrentUser: false),
        ]
        for outcome in [CompetitionEndAlertViewModel.EndOutcome.won, .mid, .last] {
            let card = CompetitionShareCardView(
                outcome: outcome,
                competitionName: "Saturday Step Showdown",
                accent: "You won.",
                entries: entries,
                scoringUnit: .points,
                placement: 1,
                youFinishedTitle: "You finished 1st of 6",
                subline: "First place is yours.",
                score: "612",
                unitTag: "PTS"
            )
            let renderer = ImageRenderer(content: card.environment(\.colorScheme, .light))
            renderer.scale = 3
            XCTAssertNotNil(renderer.uiImage, "Share card failed to render for outcome \(outcome)")
        }
    }
}
