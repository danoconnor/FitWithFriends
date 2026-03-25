import AuthenticationServices

public protocol IASAuthorizationAppleIDProvider {
    func createRequest() -> ASAuthorizationAppleIDRequest

    func getCredentialState(forUserID userID: String, completion: @escaping (ASAuthorizationAppleIDProvider.CredentialState, Error?) -> Void)
}
