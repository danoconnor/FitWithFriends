import XCTest
import Combine
@testable import Fit_with_Friends

// MARK: - PublicCompetitionTests

final class PublicCompetitionTests: XCTestCase {
    private var competitionManager: CompetitionManager!
    private var mockAuthenticationManager: MockAuthenticationManager!
    private var mockCompetitionService: MockCompetitionService!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockAuthenticationManager = MockAuthenticationManager()
        mockCompetitionService = MockCompetitionService()
        cancellables = []

        competitionManager = CompetitionManager(
            authenticationManager: mockAuthenticationManager,
            competitionService: mockCompetitionService
        )
    }

    override func tearDown() {
        competitionManager = nil
        mockAuthenticationManager = nil
        mockCompetitionService = nil
        cancellables = nil
        super.tearDown()
    }

    func test_refreshPublicCompetitions_shouldCallServiceAndUpdatePublishedProperty() async {
        // Arrange
        let competitionId = UUID()
        let publicCompetition = PublicCompetition(
            competitionId: competitionId,
            displayName: "Test Public Competition",
            startDate: Date(),
            endDate: Date().addingTimeInterval(TimeInterval.xtDays(7)),
            memberCount: 5,
            isUserMember: false
        )
        mockCompetitionService.return_getPublicCompetitions = PublicCompetitionsResponse(
            competitions: [publicCompetition],
            isUserPro: false
        )

        // Act
        await competitionManager.refreshPublicCompetitions()

        // Assert
        XCTAssertEqual(mockCompetitionService.getPublicCompetitionsCallCount, 1, "getPublicCompetitions should be called once")
        XCTAssertEqual(competitionManager.publicCompetitions.count, 1, "publicCompetitions should contain one item")
        XCTAssertEqual(competitionManager.publicCompetitions.first?.competitionId, competitionId, "The competition ID should match")
    }

    func test_refreshPublicCompetitions_serviceError_shouldNotCrash() async {
        // Arrange - no return value set, so MockCompetitionService will throw HttpError.generic

        // Act
        await competitionManager.refreshPublicCompetitions()

        // Assert - publicCompetitions should remain empty and no crash should occur
        XCTAssertEqual(mockCompetitionService.getPublicCompetitionsCallCount, 1, "getPublicCompetitions should be called once")
        XCTAssertEqual(competitionManager.publicCompetitions.count, 0, "publicCompetitions should remain empty after a service error")
    }

    func test_joinPublicCompetition_shouldCallServiceWithCorrectId() async throws {
        // Arrange
        let competitionId = UUID()

        // Act
        try await competitionManager.joinPublicCompetition(competitionId: competitionId)

        // Assert
        XCTAssertEqual(mockCompetitionService.joinPublicCompetitionCallCount, 1, "joinPublicCompetition should be called once")
        XCTAssertEqual(mockCompetitionService.param_joinPublicCompetition_competitionId, competitionId, "Competition ID passed to service should match")
    }

    func test_joinPublicCompetition_serviceError_shouldThrow() async {
        // Arrange
        let competitionId = UUID()
        mockCompetitionService.return_joinPublicCompetition_error = HttpError.testError

        // Act & Assert
        do {
            try await competitionManager.joinPublicCompetition(competitionId: competitionId)
            XCTFail("Expected error to be thrown but got none")
        } catch {
            XCTAssertEqual(mockCompetitionService.joinPublicCompetitionCallCount, 1, "joinPublicCompetition should have been called once before throwing")
        }
    }
}

// MARK: - HomepageViewModelTests

final class HomepageViewModelTests: XCTestCase {
    private var homepageViewModel: HomepageViewModel!
    private var mockAuthenticationManager: MockAuthenticationManager!
    private var mockCompetitionManager: MockCompetitionManager!
    private var mockHealthKitManager: MockHealthKitManager!
    private var mockSubscriptionManager: MockSubscriptionManager!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockAuthenticationManager = MockAuthenticationManager()
        mockCompetitionManager = MockCompetitionManager()
        mockHealthKitManager = MockHealthKitManager()
        mockSubscriptionManager = MockSubscriptionManager()
        cancellables = []

        homepageViewModel = HomepageViewModel(
            authenticationManager: mockAuthenticationManager,
            competitionManager: mockCompetitionManager,
            healthKitManager: mockHealthKitManager,
            subscriptionManager: mockSubscriptionManager
        )
    }

    override func tearDown() {
        homepageViewModel = nil
        mockAuthenticationManager = nil
        mockCompetitionManager = nil
        mockHealthKitManager = nil
        mockSubscriptionManager = nil
        cancellables = nil
        super.tearDown()
    }

    func test_isUserPro_shouldReflectSubscriptionManagerState() {
        // Arrange
        let expectation = XCTestExpectation(description: "isUserPro should update to true")
        var receivedValues: [Bool] = []

        homepageViewModel.$isUserPro
            .sink { value in
                receivedValues.append(value)
                // Skip the initial false value; fulfill once we see true
                if value == true {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        mockSubscriptionManager.return_isUserPro = true

        // Assert
        wait(for: [expectation], timeout: 2)
        XCTAssertTrue(homepageViewModel.isUserPro, "isUserPro should be true after subscription manager publishes true")
    }

    func test_publicCompetitions_shouldReflectCompetitionManagerState() {
        // Arrange
        let competitionId = UUID()
        let publicCompetition = PublicCompetition(
            competitionId: competitionId,
            displayName: "Public Test Competition",
            startDate: Date(),
            endDate: Date().addingTimeInterval(TimeInterval.xtDays(7)),
            memberCount: 10,
            isUserMember: false
        )

        let expectation = XCTestExpectation(description: "publicCompetitions should update to contain the new competition")

        homepageViewModel.$publicCompetitions
            .sink { competitions in
                // Skip the initial nil/empty value; fulfill once we see our competition
                if let competitions = competitions, competitions.contains(where: { $0.competitionId == competitionId }) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        mockCompetitionManager.return_publicCompetitions = [publicCompetition]

        // Assert
        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(homepageViewModel.publicCompetitions?.count, 1, "publicCompetitions should contain one competition")
        XCTAssertEqual(homepageViewModel.publicCompetitions?.first?.competitionId, competitionId, "The competition ID should match")
    }
}
