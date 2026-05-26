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

        viewModel.competitionName = competitionName
        viewModel.startDate = startDate
        viewModel.endDate = endDate
        viewModel.createCompetition()

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

    func test_createCompetition_onSuccess_advancesToInviteStep() async {
        let viewModel = makeViewModel()
        let startDate = Date()
        let endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)

        viewModel.competitionName = "My Competition"
        viewModel.startDate = startDate
        viewModel.endDate = endDate

        let stepExpectation = XCTestExpectation(description: "wizard advances to invite step")
        viewModel.$currentStep
            .dropFirst()
            .filter { $0 == .invite }
            .first()
            .sink { _ in stepExpectation.fulfill() }
            .store(in: &cancellables)

        viewModel.createCompetition()

        await fulfillment(of: [stepExpectation], timeout: 3.0)
        XCTAssertEqual(viewModel.currentStep, .invite,
                       "viewmodel should advance to invite step after successful create")
        XCTAssertEqual(viewModel.lastCreatedCompetitionName, "My Competition")
    }

    // MARK: - Templates + step navigation

    func test_templates_includesAllFiveCanonicalTemplates() {
        let ids = CreateCompetitionViewModel.templates.map(\.id)
        XCTAssertEqual(ids, [
            "quick-weekend",
            "friends-challenge",
            "step-streak",
            "workout-wars",
            "monthly-showdown",
        ])
    }

    func test_applyTemplate_prefillsRuleAndAdvancesToScoringStep() {
        let viewModel = makeViewModel()
        let template = CreateCompetitionViewModel.templates.first { $0.id == "step-streak" }!

        viewModel.applyTemplate(template)

        XCTAssertEqual(viewModel.currentStep, .scoring)
        XCTAssertEqual(viewModel.ruleKind, .daily)
        XCTAssertEqual(viewModel.dailyMetric, .steps)
        XCTAssertEqual(viewModel.competitionName, "Step Streak")
        // Duration of 7 days → end should be ~7 days after start.
        let diff = viewModel.endDate.timeIntervalSince(viewModel.startDate)
        XCTAssertEqual(diff, 86_400 * 7, accuracy: 1.0)
    }

    func test_applyTemplate_monthlyShowdown_preservesDailyCap() {
        let viewModel = makeViewModel()
        let template = CreateCompetitionViewModel.templates.first { $0.id == "monthly-showdown" }!

        viewModel.applyTemplate(template)

        XCTAssertEqual(viewModel.currentStep, .scoring)
        XCTAssertEqual(viewModel.ruleKind, .rings)
        XCTAssertTrue(viewModel.dailyCapEnabled)
        XCTAssertEqual(viewModel.dailyCap, 500)
    }

    func test_startBlank_resetsRuleToDefaultAndAdvances() {
        let viewModel = makeViewModel()
        // Pre-modify some state to make sure startBlank clears it.
        viewModel.ruleKind = .workouts
        viewModel.workoutMetric = .calories

        viewModel.startBlank()

        XCTAssertEqual(viewModel.currentStep, .scoring)
        XCTAssertEqual(viewModel.ruleKind, .rings)
        XCTAssertEqual(viewModel.competitionName, "")
    }

    func test_goBack_fromScoring_returnsToTemplates() {
        let viewModel = makeViewModel()
        viewModel.currentStep = .scoring

        viewModel.goBack()

        XCTAssertEqual(viewModel.currentStep, .templates)
    }

    func test_goBack_fromTemplates_dismissesSheet() {
        homepageSheetViewModel.updateState(sheet: .createCompetition, state: true)
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.currentStep, .templates)

        viewModel.goBack()

        // The sheet should be dismissed at this point.
        XCTAssertFalse(homepageSheetViewModel.shouldShowSheet)
    }

    // MARK: - Pro gating (soft-gate)

    func test_requiresProUserMissing_falseForDefaultRingsConfig_whenFree() {
        mockSubscriptionManager.return_isUserPro = false
        let viewModel = makeViewModel()
        // Default rings config is allowed for free users.
        XCTAssertFalse(viewModel.requiresProUserMissing)
    }

    func test_requiresProUserMissing_trueForNonRingsRule_whenFree() {
        mockSubscriptionManager.return_isUserPro = false
        let viewModel = makeViewModel()
        viewModel.ruleKind = .daily

        XCTAssertTrue(viewModel.requiresProUserMissing)
    }

    func test_requiresProUserMissing_trueWhenRingsCustomized_whenFree() {
        mockSubscriptionManager.return_isUserPro = false
        let viewModel = makeViewModel()
        viewModel.includeStand = false  // dropping a ring counts as customization

        XCTAssertTrue(viewModel.requiresProUserMissing)
    }

    func test_requiresProUserMissing_falseWhenUserIsPro() {
        mockSubscriptionManager.return_isUserPro = true
        let viewModel = makeViewModel()
        viewModel.ruleKind = .workouts
        viewModel.workoutMetric = .duration

        XCTAssertFalse(viewModel.requiresProUserMissing)
    }

    func test_canSubmit_falseWhenNameEmpty() {
        mockSubscriptionManager.return_isUserPro = true
        let viewModel = makeViewModel()
        viewModel.competitionName = ""

        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_canSubmit_falseWhenZeroRingsSelected() {
        mockSubscriptionManager.return_isUserPro = true
        let viewModel = makeViewModel()
        viewModel.competitionName = "Foo"
        viewModel.includeCalories = false
        viewModel.includeExercise = false
        viewModel.includeStand = false

        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_canSubmit_trueForValidProConfig() {
        mockSubscriptionManager.return_isUserPro = true
        let viewModel = makeViewModel()
        viewModel.competitionName = "Foo"
        viewModel.ruleKind = .daily
        viewModel.dailyMetric = .steps

        XCTAssertTrue(viewModel.canSubmit)
    }

    // MARK: - buildRule branches

    func test_buildRule_normalisesToDefaultWhenAllRingsAndNoCustomisation() {
        let viewModel = makeViewModel()
        // Out-of-box defaults match `.default`.
        let rule = viewModel.buildRule()
        XCTAssertTrue(rule.isDefault)
    }

    func test_buildRule_ringsWithSubsetAndMinGoals() {
        let viewModel = makeViewModel()
        viewModel.includeStand = false
        viewModel.enforceMinGoals = true
        viewModel.minCalories = 350

        let rule = viewModel.buildRule()
        guard case let .rings(rings, minGoals, _) = rule else {
            return XCTFail("Expected rings rule, got \(rule)")
        }
        XCTAssertFalse(rings.contains(.stand))
        XCTAssertEqual(minGoals?.calories, 350)
    }

    func test_buildRule_workoutsCarriesMetricAndTypes() {
        let viewModel = makeViewModel()
        viewModel.ruleKind = .workouts
        viewModel.workoutMetric = .calories
        viewModel.selectedActivityTypes = [37, 52]  // arbitrary HK raw values

        let rule = viewModel.buildRule()
        guard case let .workouts(metric, types) = rule else {
            return XCTFail("Expected workouts rule, got \(rule)")
        }
        XCTAssertEqual(metric, .calories)
        XCTAssertEqual(types, [37, 52])
    }

    func test_buildRule_workoutsEmptyTypesBecomesNil() {
        let viewModel = makeViewModel()
        viewModel.ruleKind = .workouts
        viewModel.workoutMetric = .duration
        viewModel.selectedActivityTypes = []

        let rule = viewModel.buildRule()
        guard case let .workouts(_, types) = rule else {
            return XCTFail("Expected workouts rule, got \(rule)")
        }
        XCTAssertNil(types, "Empty type set should serialize as nil (any-workout)")
    }

    func test_buildRule_dailySteps() {
        let viewModel = makeViewModel()
        viewModel.ruleKind = .daily
        viewModel.dailyMetric = .steps

        let rule = viewModel.buildRule()
        guard case let .daily(metric) = rule else {
            return XCTFail("Expected daily rule, got \(rule)")
        }
        XCTAssertEqual(metric, .steps)
    }
}
