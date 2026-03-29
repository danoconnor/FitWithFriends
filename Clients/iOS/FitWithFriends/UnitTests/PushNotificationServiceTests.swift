import XCTest
@testable import Fit_with_Friends

final class PushNotificationServiceTests: XCTestCase {
    private var pushNotificationService: PushNotificationService!
    private var mockHttpConnector: MockHttpConnector!
    private var mockTokenManager: MockTokenManager!
    private var mockServerEnvironmentManager: MockServerEnvironmentManager!

    override func setUp() {
        super.setUp()
        mockHttpConnector = MockHttpConnector()
        mockTokenManager = MockTokenManager()
        mockServerEnvironmentManager = MockServerEnvironmentManager()

        pushNotificationService = PushNotificationService(
            httpConnector: mockHttpConnector,
            serverEnvironmentManager: mockServerEnvironmentManager,
            tokenManager: mockTokenManager
        )
    }

    override func tearDown() {
        pushNotificationService = nil
        mockHttpConnector = nil
        mockTokenManager = nil
        mockServerEnvironmentManager = nil
        super.tearDown()
    }

    func test_registerPushToken_shouldMakeRequestToCorrectEndpoint() async throws {
        // Arrange
        let mockToken = Token(
            accessToken: "mockAccessToken",
            accessTokenExpiry: Date(timeIntervalSinceNow: 3600),
            refreshToken: nil,
            userId: "mockUser"
        )
        mockTokenManager.return_token = mockToken
        mockHttpConnector.return_data = EmptyResponse()

        // Act
        try await pushNotificationService.registerPushToken("testPushToken", appInstallId: "test-install-id")

        // Assert
        XCTAssertTrue(mockHttpConnector.param_url?.contains("/pushNotifications/register") ?? false)
        XCTAssertEqual(mockHttpConnector.param_method, .post)
    }

    func test_registerPushToken_shouldIncludeBearerTokenHeader() async throws {
        // Arrange
        let mockToken = Token(
            accessToken: "mockAccessToken",
            accessTokenExpiry: Date(timeIntervalSinceNow: 3600),
            refreshToken: nil,
            userId: "mockUser"
        )
        mockTokenManager.return_token = mockToken
        mockHttpConnector.return_data = EmptyResponse()

        // Act
        try await pushNotificationService.registerPushToken("testPushToken", appInstallId: "test-install-id")

        // Assert
        XCTAssertEqual(mockHttpConnector.param_headers?["Authorization"], "Bearer mockAccessToken")
    }

    func test_registerPushToken_withNoAuthToken_shouldThrowError() async throws {
        // Arrange
        mockTokenManager.return_token = nil

        // Act & Assert
        do {
            try await pushNotificationService.registerPushToken("testPushToken", appInstallId: "test-install-id")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
