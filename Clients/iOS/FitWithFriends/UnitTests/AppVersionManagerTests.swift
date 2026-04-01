//
//  AppVersionManagerTests.swift
//  FitWithFriends
//

import XCTest
@testable import Fit_with_Friends

final class AppVersionManagerTests: XCTestCase {
    private var appVersionManager: AppVersionManager!
    private var mockAppMetadataService: MockAppMetadataService!

    override func setUp() {
        super.setUp()
        mockAppMetadataService = MockAppMetadataService()
        appVersionManager = AppVersionManager(appMetadataService: mockAppMetadataService)
    }

    override func tearDown() {
        appVersionManager = nil
        mockAppMetadataService = nil
        super.tearDown()
    }

    // MARK: - checkAppVersion

    func test_checkAppVersion_serviceThrows_doesNotBlockApp() async {
        mockAppMetadataService.return_getIosBuildVersions_error = HttpError.generic

        await appVersionManager.checkAppVersion()

        XCTAssertEqual(appVersionManager.versionAlertState, .none)
    }

    func test_checkAppVersion_serviceThrows_callsServiceOnce() async {
        mockAppMetadataService.return_getIosBuildVersions_error = HttpError.generic

        await appVersionManager.checkAppVersion()

        XCTAssertEqual(mockAppMetadataService.getIosBuildVersionsCallCount, 1)
    }

    // MARK: - determineAlertState

    func test_determineAlertState_belowRequired_returnsRequiredUpdate() {
        let result = appVersionManager.determineAlertState(
            currentBuild: "20260301.1200",
            versions: IosBuildVersionsDTO(recommendedBuild: "20260401.1200", requiredBuild: "20260401.0000")
        )
        XCTAssertEqual(result, .requiredUpdate)
    }

    func test_determineAlertState_meetsRequiredButBelowRecommended_returnsRecommendedUpdate() {
        let result = appVersionManager.determineAlertState(
            currentBuild: "20260401.0000",
            versions: IosBuildVersionsDTO(recommendedBuild: "20260401.1200", requiredBuild: "20260401.0000")
        )
        XCTAssertEqual(result, .recommendedUpdate)
    }

    func test_determineAlertState_meetsRecommended_returnsNone() {
        let result = appVersionManager.determineAlertState(
            currentBuild: "20260401.1200",
            versions: IosBuildVersionsDTO(recommendedBuild: "20260401.1200", requiredBuild: "20260401.0000")
        )
        XCTAssertEqual(result, .none)
    }

    func test_determineAlertState_aboveRecommended_returnsNone() {
        let result = appVersionManager.determineAlertState(
            currentBuild: "20260402.0000",
            versions: IosBuildVersionsDTO(recommendedBuild: "20260401.1200", requiredBuild: "20260401.0000")
        )
        XCTAssertEqual(result, .none)
    }

    // MARK: - compareSemanticVersions

    func test_compareSemanticVersions_equalVersions_returnsSame() {
        XCTAssertEqual(compareSemanticVersions("20260401.1200", "20260401.1200"), .orderedSame)
    }

    func test_compareSemanticVersions_olderLeft_returnsAscending() {
        XCTAssertEqual(compareSemanticVersions("20260331.2359", "20260401.0000"), .orderedAscending)
    }

    func test_compareSemanticVersions_integerNotStringComparison_returnsDescending() {
        // "1.0.10" > "1.0.9" — validates integer comparison (not lexicographic)
        XCTAssertEqual(compareSemanticVersions("1.0.10", "1.0.9"), .orderedDescending)
    }

    func test_compareSemanticVersions_missingComponent_treatedAsZero() {
        // "1.0" == "1.0.0"
        XCTAssertEqual(compareSemanticVersions("1.0", "1.0.0"), .orderedSame)
    }
}
