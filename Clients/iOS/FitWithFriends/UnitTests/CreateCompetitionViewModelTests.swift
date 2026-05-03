//
//  CreateCompetitionViewModelTests.swift
//  FitWithFriends
//

import Combine
import XCTest
@testable import Fit_with_Friends

@MainActor
final class CreateCompetitionViewModelTests: XCTestCase {
    private var mockSubscriptionManager: MockSubscriptionManager!
    private var mockCompetitionManager: MockCompetitionManager!
    private var mockAuthenticationManager: MockAuthenticationManager!
    private var homepageSheetViewModel: HomepageSheetViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockSubscriptionManager = MockSubscriptionManager()
        mockCompetitionManager = MockCompetitionManager()
        mockAuthenticationManager = MockAuthenticationManager()
        homepageSheetViewModel = HomepageSheetViewModel(
            appProtocolHandler: MockAppProtocolHandler(),
            healthKitManager: MockHealthKitManager()
        )
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        mockSubscriptionManager = nil
        mockCompetitionManager = nil
        mockAuthenticationManager = nil
        homepageSheetViewModel = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeViewModel() -> CreateCompetitionViewModel {
        return CreateCompetitionViewModel(
            authenticationManager: mockAuthenticationManager,
            competitionManager: mockCompetitionManager,
            subscriptionManager: mockSubscriptionManager,
            homepageSheetViewModel: homepageSheetViewModel
        )
    }

    // MARK: - isUserPro initial value

    func test_isUserPro_initialValue_false_whenSubscriptionManagerIsFalse() {
        mockSubscriptionManager.return_isUserPro = false
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.isUserPro)
    }

    func test_isUserPro_initialValue_true_whenSubscriptionManagerIsTrue() {
        mockSubscriptionManager.return_isUserPro = true
        let viewModel = makeViewModel()
        XCTAssertTrue(viewModel.isUserPro)
    }

    // MARK: - isUserPro reactive updates

    func test_isUserPro_updatesReactively_whenSubscriptionManagerChanges() async {
        mockSubscriptionManager.return_isUserPro = false
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.isUserPro)

        let expectation = XCTestExpectation(description: "isUserPro updates to true")

        viewModel.$isUserPro
            .dropFirst() // skip initial value
            .sink { isUserPro in
                if isUserPro {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        mockSubscriptionManager.return_isUserPro = true

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(viewModel.isUserPro)
    }

    func test_isUserPro_multipleUpdates() async {
        mockSubscriptionManager.return_isUserPro = false
        let viewModel = makeViewModel()

        // Observe the first update: false → true
        let firstUpdateExpectation = XCTestExpectation(description: "isUserPro updates to true")
        viewModel.$isUserPro
            .dropFirst()
            .filter { $0 == true }
            .first()
            .sink { _ in firstUpdateExpectation.fulfill() }
            .store(in: &cancellables)

        mockSubscriptionManager.return_isUserPro = true
        await fulfillment(of: [firstUpdateExpectation], timeout: 2.0)
        XCTAssertTrue(viewModel.isUserPro)

        // Observe the second update: true → false
        let secondUpdateExpectation = XCTestExpectation(description: "isUserPro updates back to false")
        viewModel.$isUserPro
            .dropFirst()
            .filter { $0 == false }
            .first()
            .sink { _ in secondUpdateExpectation.fulfill() }
            .store(in: &cancellables)

        mockSubscriptionManager.return_isUserPro = false
        await fulfillment(of: [secondUpdateExpectation], timeout: 2.0)
        XCTAssertFalse(viewModel.isUserPro)
    }

    // MARK: - createCompetition

    func test_createCompetition_callsCompetitionManagerWithCorrectParams() async {
        let viewModel = makeViewModel()
        let startDate = Date()
        let endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let competitionName = "Test Competition"

        viewModel.createCompetition(
            competitionName: competitionName,
            startDate: startDate,
            endDate: endDate
        )

        // Wait for the async task to complete (MockCompetitionManager delays 1 second)
        let deadline = Date().addingTimeInterval(3.0)
        while mockCompetitionManager.createCompetitionCallCount == 0 && Date() < deadline {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        XCTAssertEqual(mockCompetitionManager.createCompetitionCallCount, 1)
        XCTAssertEqual(mockCompetitionManager.param_createCompetition_competitionName, competitionName)
        XCTAssertEqual(mockCompetitionManager.param_createCompetition_startDate, startDate)
        XCTAssertEqual(mockCompetitionManager.param_createCompetition_endDate, endDate)
        XCTAssertEqual(mockCompetitionManager.param_createCompetition_scoringRules, .default)
    }

    func test_createCompetition_onSuccess_dismissesCreateCompetitionSheet() async {
        homepageSheetViewModel.updateState(sheet: .createCompetition, state: true)

        // Wait for the sheet state to be applied on main queue
        let shownExpectation = XCTestExpectation(description: "sheet shown")
        homepageSheetViewModel.$shouldShowSheet
            .filter { $0 == true }
            .first()
            .sink { _ in shownExpectation.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [shownExpectation], timeout: 2.0)

        XCTAssertTrue(homepageSheetViewModel.shouldShowSheet)
        XCTAssertEqual(homepageSheetViewModel.sheetToShow, .createCompetition)

        let viewModel = makeViewModel()
        let startDate = Date()
        let endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)

        let dismissedExpectation = XCTestExpectation(description: "sheet dismissed")
        homepageSheetViewModel.$shouldShowSheet
            .dropFirst()
            .filter { $0 == false }
            .first()
            .sink { _ in dismissedExpectation.fulfill() }
            .store(in: &cancellables)

        viewModel.createCompetition(
            competitionName: "My Competition",
            startDate: startDate,
            endDate: endDate
        )

        await fulfillment(of: [dismissedExpectation], timeout: 3.0)
        XCTAssertFalse(homepageSheetViewModel.shouldShowSheet,
                       "createCompetition sheet should be dismissed after successful creation")
    }
}
