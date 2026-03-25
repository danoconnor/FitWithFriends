import AuthenticationServices

class MockASAuthorizationAppleIDProvider: IASAuthorizationAppleIDProvider {
    func createRequest() -> ASAuthorizationAppleIDRequest {
        return ASAuthorizationAppleIDRequest(coder: NSCoder())!
    }
    
    var credentialState: ASAuthorizationAppleIDProvider.CredentialState = .authorized
    var error: Error?

    func getCredentialState(forUserID userID: String, completion: @escaping (ASAuthorizationAppleIDProvider.CredentialState, Error?) -> Void) {
        completion(credentialState, error)
    }
}
