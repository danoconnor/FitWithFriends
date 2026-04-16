//
//  MockASAuthorizationControllerPresentationContextProviding.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 8/14/25.
//

#if !os(watchOS)
import AuthenticationServices

public class MockASAuthorizationControllerPresentationContextProviding: NSObject, ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
#endif
