import XCTest
import Combine
@testable import Fit_with_Friends

final class CompetitionManagerTests: XCTestCase {
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

    func test_createCompetition_shouldCallServiceAndRefreshOverviews() async throws {
        // Arrange
        let startDate = Date()
        let endDate = Date().addingTimeInterval(3600)
        let competitionName = "Test Competition"

        // Act
        try await competitionManager.createCompetition(startDate: startDate, endDate: endDate, competitionName: competitionName)

        // Assert
        XCTAssertEqual(mockCompetitionService.createCompetitionCallCount, 1, "createCompetition should be called once")
        XCTAssertEqual(mockCompetitionService.param_createCompetition_startDate, startDate, "Start date should match")
        XCTAssertEqual(mockCompetitionService.param_createCompetition_endDate, endDate, "End date should match")
        XCTAssertEqual(mockCompetitionService.param_createCompetition_competitionName, competitionName, "Competition name should match")
    }

    func test_refreshCompetitionOverviews_withLoggedInUser_shouldFetchAndUpdateOverviews() async {
        // Arrange
        let mockUserId = "mockUserId"
        mockAuthenticationManager.loggedInUserId = mockUserId
        let mockCompetitionId1 = UUID()
        mockCompetitionService.return_getUsersCompetitions = [mockCompetitionId1]
        let mockOverview1 = CompetitionOverview(id: mockCompetitionId1, name: "Mock Competition 1", start: Date(), end: Date())
        mockCompetitionService.return_getCompetitionOverview = mockOverview1 // Simulate returning the first overview

        // Act
        await competitionManager.refreshCompetitionOverviews()

        // Assert
        XCTAssertEqual(mockCompetitionService.getUsersCompetitionsCallCount, 1, "getUsersCompetitions should be called once")
        XCTAssertEqual(mockCompetitionService.param_getUsersCompetitions_userId, mockUserId, "User ID passed to getUsersCompetitions should match")
        XCTAssertEqual(mockCompetitionService.getCompetitionOverviewCallCount, 1, "getCompetitionOverview should be called for each competition")
        XCTAssertEqual(mockCompetitionService.param_getCompetitionOverview_competitionId, mockCompetitionId1, "Competition ID passed to getCompetitionOverview should match")
        XCTAssertEqual(competitionManager.competitionOverviews[mockCompetitionId1]?.competitionName, mockOverview1.competitionName, "Competition overview for ID 1 should be updated")
    }

    func test_joinCompetition_shouldCallService() async throws {
        // Arrange
        let competitionId = UUID()
        let competitionToken = "mockToken"

        // Act
        try await competitionManager.joinCompetition(competitionId: competitionId, competitionToken: competitionToken)

        // Assert
        XCTAssertEqual(mockCompetitionService.joinCompetitionCallCount, 1, "joinCompetition should be called once")
        XCTAssertEqual(mockCompetitionService.param_joinCompetition_competitionId, competitionId, "Competition ID should match")
        XCTAssertEqual(mockCompetitionService.param_joinCompetition_competitionToken, competitionToken, "Competition token should match")
    }

    func test_leaveCompetition_withLoggedInUser_shouldCallService() async throws {
        // Arrange
        let competitionId = UUID()
        let mockUserId = "mockUserId"
        mockAuthenticationManager.loggedInUserId = mockUserId

        // Act
        try await competitionManager.leaveCompetition(competitionId: competitionId)

        // Assert
        XCTAssertEqual(mockCompetitionService.removeUserFromCompetitionCallCount, 1, "removeUserFromCompetition should be called once")
        XCTAssertEqual(mockCompetitionService.param_removeUserFromCompetition_userId, mockUserId, "User ID should match")
        XCTAssertEqual(mockCompetitionService.param_removeUserFromCompetition_competitionId, competitionId, "Competition ID should match")
    }

    func test_leaveCompetition_withoutLoggedInUser_shouldThrowError() async {
        // Arrange
        let competitionId = UUID()
        mockAuthenticationManager.loggedInUserId = nil

        // Act & Assert
        await XCTAssertThrowsErrorAsync(try await competitionManager.leaveCompetition(competitionId: competitionId)) { error in
            guard let tokenError = error as? TokenError else {
                XCTFail("Error should be of type TokenError")
                return
            }
            XCTAssertEqual(tokenError, .notFound, "Error should indicate token not found")
        }
    }

    func XCTAssertThrowsErrorAsync<T>(_ expression: @autoclosure () async throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line, _ errorHandler: (Error) -> Void) async {
        do {
            _ = try await expression()
            XCTFail("Expected error but got none", file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}
