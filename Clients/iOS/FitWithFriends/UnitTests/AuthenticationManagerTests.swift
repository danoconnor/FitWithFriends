import XCTest
import AuthenticationServices
@testable import Fit_with_Friends

final class AuthenticationManagerTests: XCTestCase {
    private var authenticationManager: AuthenticationManager!
    private var mockAppleAuthenticationManager: MockAppleAuthenticationManager!
    private var mockAuthenticationService: MockAuthenticationService!
    private var mockTokenManager: MockTokenManager!

    override func setUp() {
        super.setUp()
        mockAppleAuthenticationManager = MockAppleAuthenticationManager()
        mockAuthenticationService = MockAuthenticationService()
        mockTokenManager = MockTokenManager()

        authenticationManager = AuthenticationManager(
            appleAuthenticationManager: mockAppleAuthenticationManager,
            authenticationService: mockAuthenticationService,
            tokenManager: mockTokenManager
        )
    }

    override func tearDown() {
        authenticationManager = nil
        mockAppleAuthenticationManager = nil
        mockAuthenticationService = nil
        mockTokenManager = nil
        super.tearDown()
    }

    func test_logout_shouldClearTokensAndSetStateToNotLoggedIn() {
        // Act
        authenticationManager.logout()

        // Assert
        XCTAssertEqual(mockTokenManager.deleteAllTokensCallCount, 1, "deleteAllTokens should be called once")
        XCTAssertNil(authenticationManager.loggedInUserId, "User ID should be nil after logout")
        XCTAssertEqual(authenticationManager.loginState, .notLoggedIn(nil), "Login state should be notLoggedIn")
    }

    func test_beginLogin_shouldSetStateToInProgressAndCallAppleLogin() {
        // Arrange
        let mockDelegate = MockASAuthorizationControllerPresentationContextProviding()

        // Act
        authenticationManager.beginLogin(with: mockDelegate)

        // Assert
        XCTAssertEqual(authenticationManager.loginState, .inProgress, "Login state should be inProgress")
        XCTAssertEqual(mockAppleAuthenticationManager.beginAppleLoginCallCount, 1, "beginAppleLogin should be called once")
    }

    func test_setInitialLoginState_withValidAppleAccountAndCachedToken_shouldSetStateToLoggedIn() {
        // Arrange
        mockAppleAuthenticationManager.return_isAppleAccountValid = true
        mockTokenManager.return_token = Token(
            accessToken: "mockAccessToken",
            accessTokenExpiry: Date(timeIntervalSinceNow: 3600),
            refreshToken: "mockRefreshToken",
            userId: "mockUser"
        )

        // Act
        authenticationManager = AuthenticationManager(
            appleAuthenticationManager: mockAppleAuthenticationManager,
            authenticationService: mockAuthenticationService,
            tokenManager: mockTokenManager
        )

        // Assert
        XCTAssertEqual(authenticationManager.loginState, .loggedIn, "Login state should be loggedIn")
        XCTAssertEqual(authenticationManager.loggedInUserId, "mockUser", "User ID should match cached token")
    }

    func test_setInitialLoginState_withInvalidAppleAccount_shouldSetStateToNotLoggedIn() {
        // Arrange
        mockAppleAuthenticationManager.return_isAppleAccountValid = false

        // Act
        authenticationManager = AuthenticationManager(
            appleAuthenticationManager: mockAppleAuthenticationManager,
            authenticationService: mockAuthenticationService,
            tokenManager: mockTokenManager
        )

        // Assert
        XCTAssertEqual(authenticationManager.loginState, .notLoggedIn(nil), "Login state should be notLoggedIn")
    }

    func test_authenticationCompleted_withSuccess_shouldStoreTokenAndSetStateToLoggedIn() {
        // Arrange
        let token = Token(
            accessToken: "mockAccessToken",
            accessTokenExpiry: Date(timeIntervalSinceNow: 3600),
            refreshToken: "mockRefreshToken",
            userId: "mockUser"
        )

        // Act
        authenticationManager.authenticationCompleted(result: .success(token))

        // Assert
        XCTAssertEqual(authenticationManager.loginState, .loggedIn, "Login state should be loggedIn")
        XCTAssertEqual(authenticationManager.loggedInUserId, "mockUser", "User ID should match token")
        XCTAssertEqual(mockTokenManager.storeTokenCallCount, 1, "storeToken should be called once")
    }

    func test_authenticationCompleted_withFailure_shouldSetStateToNotLoggedIn() {
        // Arrange
        let error = NSError(domain: "TestError", code: 1, userInfo: nil)

        // Act
        authenticationManager.authenticationCompleted(result: .failure(error))

        // Assert
        XCTAssertEqual(authenticationManager.loginState, .notLoggedIn(error), "Login state should be notLoggedIn with error")
        XCTAssertNil(authenticationManager.loggedInUserId, "User ID should be nil")
    }
}
