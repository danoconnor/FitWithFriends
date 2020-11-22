//
//  WelcomeView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import SwiftUI

struct WelcomeView: View {
    @State private var createAccountViewShown = false

    var body: some View {
        VStack {
            Spacer()

            Text("Fit With Friends")
                .font(.title)

            Spacer()

            Button("Login") { }
                .font(.title2)
                .padding()

            Button ("Create Account") {
                createAccountViewShown = true
            }
            .font(.footnote)
            .padding()
            .sheet(isPresented: $createAccountViewShown, content: {
                CreateAccountView()
            })

            Spacer()
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
