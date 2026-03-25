import XCTest
@testable import Fit_with_Friends

final class TokenManagerTests: XCTestCase {
    private var tokenManager: TokenManager!
    private var mockKeychainUtilities: MockKeychainUtilities!

    override func setUp() {
        super.setUp()
        mockKeychainUtilities = MockKeychainUtilities()
        tokenManager = TokenManager(keychainUtilities: mockKeychainUtilities)
    }

    override func tearDown() {
        tokenManager = nil
        mockKeychainUtilities = nil
        super.tearDown()
    }

    func test_getCachedToken_withValidTokenInMemory_shouldReturnToken() throws {
        // Arrange
        let token = Token(
            accessToken: "mockAccessToken",
            accessTokenExpiry: Date(timeIntervalSinceNow: 3600),
            refreshToken: "mockRefreshToken",
            userId: "mockUser"
        )
        tokenManager.storeToken(token)

        // Act
        let cachedToken = try tokenManager.getCachedToken()

        // Assert
        XCTAssertEqual(cachedToken.accessToken, "mockAccessToken", "Access token should match")
        XCTAssertEqual(cachedToken.userId, "mockUser", "User ID should match")
    }

    func test_getCachedToken_withExpiredTokenInMemory_shouldThrowError() {
        // Arrange
        let token = Token(
            accessToken: "mockAccessToken",
            accessTokenExpiry: Date(timeIntervalSinceNow: -3600),
            refreshToken: "mockRefreshToken",
            userId: "mockUser"
        )
        tokenManager.storeToken(token)

        // Act & Assert
        XCTAssertThrowsError(try tokenManager.getCachedToken()) { error in
            guard let tokenError = error as? TokenError else {
                XCTFail("Error should be of type TokenError")
                return
            }
            XCTAssertEqual(tokenError, .expired(token: token), "Error should indicate token is expired")
        }
    }

    func test_storeToken_shouldSaveTokenToKeychain() {
        // Arrange
        let token = Token(
            accessToken: "mockAccessToken",
            accessTokenExpiry: Date(timeIntervalSinceNow: 3600),
            refreshToken: "mockRefreshToken",
            userId: "mockUser"
        )

        // Act
        tokenManager.storeToken(token)

        // Assert
        XCTAssertEqual(mockKeychainUtilities.writeKeychainItemCallCount, 1, "writeKeychainItem should be called once")
    }

    func test_deleteAllTokens_shouldClearKeychainAndMemory() {
        // Arrange
        let token = Token(
            accessToken: "mockAccessToken",
            accessTokenExpiry: Date(timeIntervalSinceNow: 3600),
            refreshToken: "mockRefreshToken",
            userId: "mockUser"
        )
        tokenManager.storeToken(token)

        // Act
        tokenManager.deleteAllTokens()

        // Assert
        XCTAssertEqual(mockKeychainUtilities.deleteKeychainItemCallCount, 1, "deleteKeychainItem should be called once")
        XCTAssertThrowsError(try tokenManager.getCachedToken(), "Token should be cleared from memory")
    }
}
