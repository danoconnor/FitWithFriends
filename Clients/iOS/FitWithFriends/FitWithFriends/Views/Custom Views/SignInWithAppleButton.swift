//
//  SignInWithAppleButton.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/13/22.
//

import AuthenticationServices
import SwiftUI

struct SignInWithAppleButton: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme

    typealias UIViewType = ASAuthorizationAppleIDButton

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        return ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: colorScheme == .dark ? .white : .black)
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
}
