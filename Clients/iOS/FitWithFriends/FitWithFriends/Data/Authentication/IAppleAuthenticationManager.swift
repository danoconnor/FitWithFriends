import AuthenticationServices
import Foundation

/**
 A protocol defining the interface for managing Apple authentication.
 */
protocol IAppleAuthenticationManager: AnyObject {
    /// The delegate that handles Apple authentication events.
    var authenticationDelegate: AppleAuthenticationDelegate? { get set }

    /// Begins the Apple login process.
    /// - Parameters:
    ///   - presentationDelegate: The delegate responsible for presenting the Apple login UI.
    ///   - userProvidedName: An optional user-provided display name.
    func beginAppleLogin(
        presentationDelegate: ASAuthorizationControllerPresentationContextProviding,
        userProvidedName: PersonNameComponents?
    )

    /// Checks if the Apple account is valid.
    /// - Returns: A boolean indicating whether the Apple account is valid.
    func isAppleAccountValid() -> Bool
}
