//
//  WelcomeView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import SwiftUI

struct WelcomeView: View {
    let objectGraph: IObjectGraph

    @State private var createAccountViewShown = false
    @State private var loginViewShown = false

    var body: some View {
        VStack {
            Spacer()

            Text("Fit With Friends")
                .font(.title)

            Spacer()

            Button("Login") {
                loginViewShown = true
            }
            .font(.title2)
            .padding()
            .sheet(isPresented: $loginViewShown, content: {
                LoginView(objectGraph: objectGraph)
            })

            Button ("Create Account") {
                createAccountViewShown = true
            }
            .font(.footnote)
            .padding()
            .sheet(isPresented: $createAccountViewShown, content: {
                CreateAccountView(objectGraph: objectGraph)
            })

            Spacer()
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(objectGraph: MockObjectGraph())
    }
}
