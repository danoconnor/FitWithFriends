//
//  SignedOutView.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import SwiftUI

struct SignedOutView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 28))
                .foregroundStyle(Color("FwFBrandingColor"))
            Text("Sign in on iPhone")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Open FitWithFriends on your iPhone to sign in, then return here.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
