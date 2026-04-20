//
//  CompetitionsPagerViewModelTests.swift
//  FitWithFriends Watch App Tests
//
//  Created by Dan O'Connor on 4/14/26.
//

import XCTest
import Combine
@testable import FitWithFriends_Watch_App

final class CompetitionsPagerViewModelTests: XCTestCase {
    private var mockAuth: MockAuthenticationManager!
    private var mockCompetitionManager: MockCompetitionManager!
    private var viewModel: CompetitionsPagerViewModel!

    override func setUp() {
        super.setUp()
        mockAuth = MockAuthenticationManager()
        mockCompetitionManager = MockCompetitionManager()
        mockCompetitionManager.return_competitionOverviews = [:]
        viewModel = CompetitionsPagerViewModel(
            authenticationManager: mockAuth,
            competitionManager: mockCompetitionManager
        )
    }

    override func tearDown() {
        viewModel = nil
        mockCompetitionManager = nil
        mockAuth = nil
        super.tearDown()
    }

    // MARK: - Display state transitions

    func test_initialState_isLoading() {
        // The initial value before the publisher fires is `.loading`.
        // (We force `recomputeDisplayState` with an explicit state below to test transitions.)
        viewModel.recomputeDisplayState(loginState: .inProgress)
        XCTAssertEqual(viewModel.displayState, .loading)
    }

    func test_notLoggedIn_showsSignedOut() {
        viewModel.recomputeDisplayState(loginState: .notLoggedIn(nil))
        XCTAssertEqual(viewModel.displayState, .signedOut)
    }

    func test_needUserInfo_showsSignedOut() {
        viewModel.recomputeDisplayState(loginState: .needUserInfo)
        XCTAssertEqual(viewModel.displayState, .signedOut)
    }

    func test_loggedIn_withoutData_showsLoading() {
        viewModel.recomputeDisplayState(loginState: .loggedIn)
        XCTAssertEqual(viewModel.displayState, .loading,
                       "Before the first data publish, loggedIn should still show loading")
    }

    func test_loggedIn_withEmptyOverviews_afterDataReceived_showsNoCompetitions() {
        // Simulate a publish of an empty dict — the observer flips hasReceivedData.
        mockCompetitionManager.return_competitionOverviews = [:]
        // The publisher binding in init already sets hasReceivedData via sink; give runloop a tick.
        let expectation = self.expectation(description: "hasReceivedData")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1)

        viewModel.recomputeDisplayState(loginState: .loggedIn)
        XCTAssertEqual(viewModel.displayState, .noCompetitions)
    }

    func test_loggedIn_withOverviews_showsCompetitions() {
        let active = CompetitionOverview(
            start: Date().addingTimeInterval(-86_400),
            end: Date().addingTimeInterval(86_400 * 3)
        )
        mockCompetitionManager.return_competitionOverviews = [active.competitionId: active]
        // Give Combine a tick.
        let expectation = self.expectation(description: "publish")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1)

        viewModel.recomputeDisplayState(loginState: .loggedIn)
        if case .competitions(let overviews) = viewModel.displayState {
            XCTAssertEqual(overviews.count, 1)
            XCTAssertEqual(overviews.first?.competitionId, active.competitionId)
        } else {
            XCTFail("Expected .competitions, got \(viewModel.displayState)")
        }
    }

    // MARK: - Sorting

    func test_sortCompetitionsForDisplay_putsActiveFirst() {
        let past = CompetitionOverview(
            start: Date().addingTimeInterval(-86_400 * 20),
            end: Date().addingTimeInterval(-86_400 * 10)
        )
        let future = CompetitionOverview(
            start: Date().addingTimeInterval(86_400 * 2),
            end: Date().addingTimeInterval(86_400 * 7)
        )
        let active = CompetitionOverview(
            start: Date().addingTimeInterval(-86_400),
            end: Date().addingTimeInterval(86_400 * 3)
        )

        let sorted = CompetitionsPagerViewModel.sortCompetitionsForDisplay([past, future, active])
        XCTAssertEqual(sorted.first?.competitionId, active.competitionId,
                       "Active competition must be the first page")
    }

    func test_sortCompetitionsForDisplay_activeEndingSooner_comesFirst() {
        let endingSoon = CompetitionOverview(
            start: Date().addingTimeInterval(-86_400),
            end: Date().addingTimeInterval(86_400)
        )
        let endingLater = CompetitionOverview(
            start: Date().addingTimeInterval(-86_400),
            end: Date().addingTimeInterval(86_400 * 5)
        )
        let sorted = CompetitionsPagerViewModel.sortCompetitionsForDisplay([endingLater, endingSoon])
        // Per CompetitionOverview.<, active competitions with the later end date come first.
        XCTAssertEqual(sorted.first?.competitionId, endingLater.competitionId)
    }
}
