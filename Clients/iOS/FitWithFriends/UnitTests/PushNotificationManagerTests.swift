import XCTest
@testable import Fit_with_Friends

final class PushNotificationManagerTests: XCTestCase {
    private var pushNotificationManager: PushNotificationManager!
    private var mockPushNotificationService: MockPushNotificationService!
    private var testUserDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        mockPushNotificationService = MockPushNotificationService()
        testUserDefaults = UserDefaults(suiteName: "PushNotificationManagerTests")!
        testUserDefaults.removePersistentDomain(forName: "PushNotificationManagerTests")

        pushNotificationManager = PushNotificationManager(
            pushNotificationService: mockPushNotificationService,
            userDefaults: testUserDefaults
        )
    }

    override func tearDown() {
        pushNotificationManager = nil
        mockPushNotificationService = nil
        testUserDefaults.removePersistentDomain(forName: "PushNotificationManagerTests")
        testUserDefaults = nil
        super.tearDown()
    }

    func test_handleDeviceToken_shouldRegisterPushTokenWithServer() async throws {
        // Arrange
        let tokenBytes: [UInt8] = [0x01, 0x02, 0xAB, 0xCD]
        let tokenData = Data(tokenBytes)
        let expectedTokenString = "0102abcd"

        // Act
        pushNotificationManager.handleDeviceToken(tokenData)

        // Wait for async Task to complete
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Assert
        XCTAssertEqual(mockPushNotificationService.registerPushTokenCallCount, 1)
        XCTAssertEqual(mockPushNotificationService.param_registerPushToken_pushToken, expectedTokenString)
    }

    func test_handleDeviceToken_shouldUseConsistentAppInstallId() async throws {
        // Arrange
        let tokenData = Data([0x01, 0x02])

        // Act - call twice
        pushNotificationManager.handleDeviceToken(tokenData)
        try await Task.sleep(nanoseconds: 2_000_000_000)
        let firstInstallId = mockPushNotificationService.param_registerPushToken_appInstallId

        pushNotificationManager.handleDeviceToken(tokenData)
        try await Task.sleep(nanoseconds: 2_000_000_000)
        let secondInstallId = mockPushNotificationService.param_registerPushToken_appInstallId

        // Assert - same install ID used both times
        XCTAssertNotNil(firstInstallId)
        XCTAssertEqual(firstInstallId, secondInstallId)
    }

    func test_handleDeviceToken_withServiceError_shouldNotThrow() async throws {
        // Arrange
        let tokenData = Data([0x01, 0x02])
        mockPushNotificationService.return_registerPushToken_error = HttpError.serverError(code: 500, details: nil)

        // Act - should not throw even if service fails
        pushNotificationManager.handleDeviceToken(tokenData)
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Assert - attempted the registration
        XCTAssertEqual(mockPushNotificationService.registerPushTokenCallCount, 1)
    }
}
