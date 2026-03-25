import Combine
import AuthenticationServices

/**
 A protocol defining the interface for managing user authentication.
 */
public protocol IAuthenticationManager: AnyObject {
    /// A publisher for the current login state of the user.
    var loginStatePublisher: Published<LoginState>.Publisher { get }

    /// The current login state
    var loginState: LoginState { get }

    /// The ID of the currently logged-in user, if any.
    var loggedInUserId: String? { get }

    /// Begins the login process.
    /// - Parameters:
    ///   - delegate: The delegate responsible for presenting the login UI.
    ///   - userProvidedName: An optional user-provided display name.
    func beginLogin(
        with delegate: ASAuthorizationControllerPresentationContextProviding,
        userProvidedName: PersonNameComponents?
    )

    /// Cancels any ongoing user input during the login process.
    func cancelUserInput()

    /// Logs out the currently logged-in user.
    func logout()
}
