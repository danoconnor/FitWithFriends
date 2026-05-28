import XCTest
@testable import Fit_with_Friends

@MainActor
final class UserCompetitionDailyDetailsViewModelTests: XCTestCase {
    private var viewModel: UserCompetitionDailyDetailsViewModel!
    private var mockCompetitionManager: MockCompetitionManager!

    private let testCompetitionId = UUID()
    private let testUserId = "testUser"
    private let testUserName = "Test User"

    override func setUp() {
        super.setUp()
        mockCompetitionManager = MockCompetitionManager()

        viewModel = UserCompetitionDailyDetailsViewModel(
            competitionManager: mockCompetitionManager,
            competitionId: testCompetitionId,
            userId: testUserId,
            userName: testUserName)
    }

    override func tearDown() {
        viewModel = nil
        mockCompetitionManager = nil
        super.tearDown()
    }

    func test_loadDetails_success_populatesSummaries() async {
        // Arrange
        let summaries = [
            DailySummary(date: Date(), caloriesBurned: 300, caloriesGoal: 400, exerciseTime: 25, exerciseTimeGoal: 30, standTime: 10, standTimeGoal: 12, points: 250),
            DailySummary(date: Date().addingTimeInterval(-86400), caloriesBurned: 400, caloriesGoal: 400, exerciseTime: 30, exerciseTimeGoal: 30, standTime: 12, standTimeGoal: 12, points: 300)
        ]
        let details = UserCompetitionDailyDetails(
            userId: testUserId,
            firstName: "Test",
            lastName: "User",
            competitionId: testCompetitionId,
            dailySummaries: summaries)
        mockCompetitionManager.return_getUserCompetitionDetails = details

        // Act
        await viewModel.loadDetails()

        // Assert
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.dailySummaries.count, 2)
        XCTAssertEqual(mockCompetitionManager.getUserCompetitionDetailsCallCount, 1)
    }

    func test_loadDetails_success_sortsByDateDescending() async {
        // Arrange
        let olderDate = Date().addingTimeInterval(-86400 * 3) // 3 days ago
        let middleDate = Date().addingTimeInterval(-86400) // 1 day ago
        let newerDate = Date() // today

        let summaries = [
            DailySummary(date: middleDate, points: 200),
            DailySummary(date: olderDate, points: 100),
            DailySummary(date: newerDate, points: 300)
        ]
        let details = UserCompetitionDailyDetails(
            userId: testUserId,
            competitionId: testCompetitionId,
            dailySummaries: summaries)
        mockCompetitionManager.return_getUserCompetitionDetails = details

        // Act
        await viewModel.loadDetails()

        // Assert
        XCTAssertEqual(viewModel.dailySummaries.count, 3)
        // Most recent first
        XCTAssertEqual(viewModel.dailySummaries[0].points, 300)
        XCTAssertEqual(viewModel.dailySummaries[1].points, 200)
        XCTAssertEqual(viewModel.dailySummaries[2].points, 100)
    }

    func test_loadDetails_failure_setsErrorMessage() async {
        // Arrange
        mockCompetitionManager.return_getUserCompetitionDetails_error = NSError(domain: "Test", code: 1)

        // Act
        await viewModel.loadDetails()

        // Assert
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.dailySummaries.isEmpty)
    }

    func test_loadDetails_calculatedTotalPoints() async {
        // Arrange
        let summaries = [
            DailySummary(date: Date(), points: 150.5),
            DailySummary(date: Date().addingTimeInterval(-86400), points: 275.3),
            DailySummary(date: Date().addingTimeInterval(-86400 * 2), points: 100.0)
        ]
        let details = UserCompetitionDailyDetails(
            userId: testUserId,
            competitionId: testCompetitionId,
            dailySummaries: summaries)
        mockCompetitionManager.return_getUserCompetitionDetails = details

        // Act
        await viewModel.loadDetails()

        // Assert
        XCTAssertEqual(viewModel.totalPoints, 525.8, accuracy: 0.01)
    }

    // MARK: - Redesign derivations

    func test_dailyAverage_isZeroWhenEmpty() {
        XCTAssertEqual(viewModel.dailyAverage, 0)
        XCTAssertEqual(viewModel.dailyAverageDisplay, "0 pts")
    }

    func test_dailyAverage_dividesTotalByDayCount() async {
        let summaries = [
            DailySummary(date: Date(), points: 100),
            DailySummary(date: Date().addingTimeInterval(-86400), points: 200),
            DailySummary(date: Date().addingTimeInterval(-86400 * 2), points: 300),
        ]
        mockCompetitionManager.return_getUserCompetitionDetails = UserCompetitionDailyDetails(
            userId: testUserId,
            competitionId: testCompetitionId,
            dailySummaries: summaries)

        await viewModel.loadDetails()

        XCTAssertEqual(viewModel.dailyAverage, 200, accuracy: 0.01)
    }

    func test_fullRingDayCount_countsOnlyDaysWithAllThreeRings() async {
        let summaries = [
            // All three closed
            DailySummary(date: Date(), caloriesBurned: 500, caloriesGoal: 400,
                         exerciseTime: 40, exerciseTimeGoal: 30,
                         standTime: 12, standTimeGoal: 12, points: 300),
            // Move missing
            DailySummary(date: Date().addingTimeInterval(-86400),
                         caloriesBurned: 300, caloriesGoal: 400,
                         exerciseTime: 40, exerciseTimeGoal: 30,
                         standTime: 12, standTimeGoal: 12, points: 220),
            // All three closed
            DailySummary(date: Date().addingTimeInterval(-86400 * 2),
                         caloriesBurned: 500, caloriesGoal: 400,
                         exerciseTime: 40, exerciseTimeGoal: 30,
                         standTime: 12, standTimeGoal: 12, points: 300),
            // Non-ring competition data (caloriesGoal 0)
            DailySummary(date: Date().addingTimeInterval(-86400 * 3),
                         caloriesGoal: 0, points: 5000),
        ]
        mockCompetitionManager.return_getUserCompetitionDetails = UserCompetitionDailyDetails(
            userId: testUserId,
            competitionId: testCompetitionId,
            dailySummaries: summaries)

        await viewModel.loadDetails()

        XCTAssertEqual(viewModel.fullRingDayCount, 2)
    }

    func test_personalBestDate_picksHighestPointsDay() async {
        let best = Date().addingTimeInterval(-86400)
        let summaries = [
            DailySummary(date: Date(), points: 200),
            DailySummary(date: best, points: 400),
            DailySummary(date: Date().addingTimeInterval(-86400 * 2), points: 100),
        ]
        mockCompetitionManager.return_getUserCompetitionDetails = UserCompetitionDailyDetails(
            userId: testUserId,
            competitionId: testCompetitionId,
            dailySummaries: summaries)

        await viewModel.loadDetails()

        XCTAssertEqual(viewModel.personalBestDate, best)
    }

    func test_personalBestDate_nilWhenEmpty() {
        XCTAssertNil(viewModel.personalBestDate)
    }

    func test_heatmapIntensities_ordersOldestFirst_andNormalisesToBest() async {
        let oldest = Date().addingTimeInterval(-86400 * 2)
        let middle = Date().addingTimeInterval(-86400)
        let newest = Date()
        // Pass in a non-chronological order to verify the sort.
        let summaries = [
            DailySummary(date: newest, points: 100),
            DailySummary(date: oldest, points: 50),
            DailySummary(date: middle, points: 200),  // best
        ]
        mockCompetitionManager.return_getUserCompetitionDetails = UserCompetitionDailyDetails(
            userId: testUserId,
            competitionId: testCompetitionId,
            dailySummaries: summaries)

        await viewModel.loadDetails()

        let heatmap = viewModel.heatmapIntensities
        XCTAssertEqual(heatmap.count, 3)
        XCTAssertEqual(heatmap[0].date, oldest)
        XCTAssertEqual(heatmap[1].date, middle)
        XCTAssertEqual(heatmap[2].date, newest)
        // Best day clamps to 1.0
        XCTAssertEqual(heatmap[1].intensity, 1.0, accuracy: 0.01)
        // Other days normalise but floor at 0.1
        XCTAssertGreaterThanOrEqual(heatmap[0].intensity, 0.1)
        XCTAssertLessThan(heatmap[0].intensity, heatmap[1].intensity)
    }

    func test_heatmapIntensities_emptyWhenNoSummaries() {
        XCTAssertTrue(viewModel.heatmapIntensities.isEmpty)
    }
}
