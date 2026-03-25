import XCTest
import AuthenticationServices
@testable import Fit_with_Friends

final class AppleAuthenticationManagerTests: XCTestCase {
    private var appleAuthenticationManager: AppleAuthenticationManager!
    private var mockAuthenticationService: MockAuthenticationService!
    private var mockKeychainUtilities: MockKeychainUtilities!
    private var mockServerEnvironmentManager: ServerEnvironmentManager!
    private var mockUserService: MockUserService!
    private var mockDelegate: MockASAuthorizationControllerPresentationContextProviding!
    private var mockAppleIDProvider: MockASAuthorizationAppleIDProvider!

    override func setUp() {
        super.setUp()
        mockAuthenticationService = MockAuthenticationService()
        mockKeychainUtilities = MockKeychainUtilities()
        mockServerEnvironmentManager = ServerEnvironmentManager(userDefaults: UserDefaults.standard)
        mockUserService = MockUserService()
        mockDelegate = MockASAuthorizationControllerPresentationContextProviding()
        mockAppleIDProvider = MockASAuthorizationAppleIDProvider()

        appleAuthenticationManager = AppleAuthenticationManager(
            appleIDProvider: mockAppleIDProvider,
            authenticationService: mockAuthenticationService,
            keychainUtilities: mockKeychainUtilities,
            serverEnvironmentManager: mockServerEnvironmentManager,
            userService: mockUserService
        )
    }

    override func tearDown() {
        appleAuthenticationManager = nil
        mockAuthenticationService = nil
        mockKeychainUtilities = nil
        mockServerEnvironmentManager = nil
        mockUserService = nil
        mockDelegate = nil
        mockAppleIDProvider = nil
        super.tearDown()
    }

    func test_beginAppleLogin_shouldPerformAuthorizationRequest() {
        // Arrange
        mockKeychainUtilities.return_getKeychainItem = "mockUserId"

        // Act
        appleAuthenticationManager.beginAppleLogin(presentationDelegate: mockDelegate)

        // Assert
        XCTAssertEqual(mockKeychainUtilities.getKeychainItemCallCount, 1, "Keychain should be queried for user ID")
        // Additional assertions to verify ASAuthorizationController behavior can be added here
    }

    func test_isAppleAccountValid_withValidAccount_shouldReturnTrue() {
        // Arrange
        mockKeychainUtilities.return_getKeychainItem = "mockUserId"
        mockAppleIDProvider.credentialState = .authorized

        // Act
        let isValid = appleAuthenticationManager.isAppleAccountValid()

        // Assert
        XCTAssertTrue(isValid, "Apple account should be valid")
    }

    func test_isAppleAccountValid_withInvalidAccount_shouldReturnFalseAndClearKeychain() {
        // Arrange
        mockKeychainUtilities.return_getKeychainItem = "mockUserId"
        mockAppleIDProvider.credentialState = .revoked

        // Act
        let isValid = appleAuthenticationManager.isAppleAccountValid()

        // Assert
        XCTAssertFalse(isValid, "Apple account should be invalid")
        XCTAssertEqual(mockKeychainUtilities.deleteKeychainItemCallCount, 1, "Keychain item should be deleted")
    }

    func test_handleAuthorization_withValidCredential_shouldFetchToken() async {
        // Arrange
        let appleCredential = AppleAuthorizationCredential(
            userId: "mockUserId",
            idToken: "mockIdToken",
            authorizationCode: "mockAuthCode",
            displayName: PersonNameComponents(givenName: "John", familyName: "Doe")
        )

        // Act
        await appleAuthenticationManager.handleAuthorization(with: appleCredential)

        // Assert
        XCTAssertEqual(mockAuthenticationService.getTokenFromAppleIdCallCount, 1, "getTokenFromAppleId should be called once")
    }

    func test_handleAuthorization_withValidCredential_shouldStoreUserIdInKeychain() async {
        // Arrange
        let appleCredential = AppleAuthorizationCredential(
            userId: "mockUserId",
            idToken: "mockIdToken",
            authorizationCode: "mockAuthCode",
            displayName: PersonNameComponents(givenName: "John", familyName: "Doe")
        )

        // Act
        await appleAuthenticationManager.handleAuthorization(with: appleCredential)

        // Assert
        XCTAssertEqual(mockKeychainUtilities.writeKeychainItemCallCount, 1, "User ID should be stored in the keychain")

        guard let keychainUserId = mockKeychainUtilities.writeKeychainItemLastValueSet as? String else {
            XCTFail("Stored keychain item should be a String")
            return
        }
        XCTAssertEqual(keychainUserId, "mockUserId", "Stored user ID should match the credential user ID")
    }

    func test_handleAuthorization_withNewUser_shouldCreateUser() async {
        // Arrange
        let appleCredential = AppleAuthorizationCredential(
            userId: "newUserId",
            idToken: "mockIdToken",
            authorizationCode: "mockAuthCode",
            displayName: PersonNameComponents(givenName: "Jane", familyName: "Doe")
        )

        // Act
        await appleAuthenticationManager.handleAuthorization(with: appleCredential)

        // Assert
        XCTAssertEqual(mockUserService.createUserCallCount, 1, "createUser should be called for a new user")
        XCTAssertEqual(mockUserService.param_createUser_userId, "newUserId", "Created user ID should match the credential user ID")
    }

    func test_handleAuthorization_withExistingUser_shouldNotCreateUser() async {
        // Arrange
        let appleCredential = AppleAuthorizationCredential(
            userId: "existingUserId",
            idToken: "mockIdToken",
            authorizationCode: "mockAuthCode",
            displayName: nil
        )

        // Act
        await appleAuthenticationManager.handleAuthorization(with: appleCredential)

        // Assert
        XCTAssertEqual(mockUserService.createUserCallCount, 0, "createUser should not be called for an existing user")
    }

    func test_handleAuthorization_withUserNotFoundFromTokenRequest_shouldCreateUser() async {
        // Arrange
        let appleCredential = AppleAuthorizationCredential(
            userId: "userNotFoundId",
            idToken: "mockIdToken",
            authorizationCode: "mockAuthCode",
            displayName: PersonNameComponents(givenName: "Alice", familyName: "Wonder")
        )

        let errorDetails = FWFErrorDetails(context: "context", errorDetails: nil, customErrorCode: FWFErrorCode.userNotFound.rawValue)
        let error = HttpError.clientError(code: 400, details: errorDetails)
        mockAuthenticationService.return_getTokenFromAppleId_error = error // Simulate user not found response

        // Act
        await appleAuthenticationManager.handleAuthorization(with: appleCredential)

        // Assert
        XCTAssertEqual(mockUserService.createUserCallCount, 1, "createUser should be called when user is not found from token request")
        XCTAssertEqual(mockUserService.param_createUser_userId, "userNotFoundId", "Created user ID should match the credential user ID")
    }
}
