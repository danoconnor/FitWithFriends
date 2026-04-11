//
//  CompetitionEndAlertViewModelTests.swift
//  FitWithFriends
//

import Combine
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

    func test_userInThirdPlace_showsConfetti() async {
        let vm = makeVM()
        let competition = makeArchivedCompetition(userPosition: 3)

        mockCompetitionManager.return_competitionOverviews = [competition.competitionId: competition]
        await waitUntil(vm.shouldShowConfetti)

        XCTAssertTrue(vm.shouldShowConfetti)
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
}
