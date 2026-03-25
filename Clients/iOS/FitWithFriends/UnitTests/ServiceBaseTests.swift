import XCTest
@testable import Fit_with_Friends

final class ServiceBaseTests: XCTestCase {
    private var serviceBase: ServiceBase!
    private var mockHttpConnector: MockHttpConnector!
    private var mockTokenManager: MockTokenManager!
    private var mockServerEnvironmentManager: MockServerEnvironmentManager!

    override func setUp() {
        super.setUp()
        mockHttpConnector = MockHttpConnector()
        mockTokenManager = MockTokenManager()
        mockServerEnvironmentManager = MockServerEnvironmentManager()

        serviceBase = ServiceBase(
            httpConnector: mockHttpConnector,
            serverEnvironmentManager: mockServerEnvironmentManager,
            tokenManager: mockTokenManager
        )
    }

    override func tearDown() {
        serviceBase = nil
        mockHttpConnector = nil
        mockTokenManager = nil
        mockServerEnvironmentManager = nil
        super.tearDown()
    }

    func test_getToken_withValidRefreshToken_shouldReturnNewToken() async throws {
        // Arrange
        let mockToken = Token(
            accessToken: "mockAccessToken",
            accessTokenExpiry: Date(timeIntervalSinceNow: -3600),
            refreshToken: "mockRefreshToken",
            userId: "mockUser"
        )
        let newToken = Token(
            accessToken: "newAccessToken",
            accessTokenExpiry: Date(timeIntervalSinceNow: 3600),
            refreshToken: "newRefreshToken",
            userId: "mockUser"
        )
        mockHttpConnector.return_data = newToken

        // Act
        let result = try await serviceBase.getToken(token: mockToken)

        // Assert
        XCTAssertEqual(result.accessToken, newToken.accessToken, "Access token should match")
        XCTAssertEqual(result.refreshToken, newToken.refreshToken, "Refresh token should match")
    }

    func test_makeRequestWithClientAuthentication_shouldIncludeBasicAuthHeader() async throws {
        // Arrange
        mockServerEnvironmentManager.clientId = "mockClientId"
        mockServerEnvironmentManager.clientSecret = "mockClientSecret"
        let expectedAuthHeader = "Basic " + ("mockClientId:mockClientSecret".data(using: .utf8)?.base64EncodedString() ?? "")
        mockHttpConnector.return_data = "Test data"

        // Act
        let _: String = try await serviceBase.makeRequestWithClientAuthentication(url: "mockUrl", method: .post)

        // Assert
        XCTAssertEqual(mockHttpConnector.param_headers?["Authorization"], expectedAuthHeader, "Authorization header should match")
    }

    func test_makeRequestWithUserAuthentication_withExpiredToken_shouldRefreshTokenAndRetry() async throws {
        // Arrange
        let expiredToken = Token(
            accessToken: "expiredAccessToken",
            accessTokenExpiry: Date(timeIntervalSinceNow: -3600),
            refreshToken: "mockRefreshToken",
            userId: "mockUser"
        )
        mockTokenManager.return_token = expiredToken
        mockHttpConnector.return_error = TokenError.expired(token: expiredToken)

        // Act
        do {
            let _: String = try await serviceBase.makeRequestWithUserAuthentication(url: "mockUrl", method: .get)
        } catch {
            // Don't care about exceptions
            // Due to our primitive mocking, we can't mock an expired token repsonse then a good token response well
            // So we'll always get an expired token error back
            // But we can see if we at least made the correct downstream requests to refresh the token
        }

        // Assert that we automatically tried to make the request to refresh the token
        XCTAssertTrue(mockHttpConnector.param_url?.contains("oauth/token") ?? false)
    }
}
