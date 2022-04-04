//
//  WelcomeView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import SwiftUI

struct WelcomeView: View {
    private let objectGraph: IObjectGraph
    @ObservedObject private var viewModel: WelcomeViewModel

    @State private var createAccountViewShown = false
    @State private var loginViewShown = false

    init(objectGraph: IObjectGraph) {
        self.objectGraph = objectGraph
        viewModel = WelcomeViewModel(authenticationManager: objectGraph.authenticationManager)
    }

    var body: some View {
        VStack {
            if viewModel.state.isFailed {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .padding(.leading)

                    Text(viewModel.state.errorMessage)
                        .padding()

                    Spacer()
                }
                .background(Color.red)
                .padding()
            }

            Spacer()

            Text("Fit With Friends")
                .font(.largeTitle)

            Spacer()

            Button( action: {
                self.viewModel.login()
            }, label: {
                SignInWithAppleButton()
                    .frame(height: 60)
                    .cornerRadius(16)
            })
            .padding()
            .sheet(isPresented: $loginViewShown, content: {
                // LoginView(objectGraph: objectGraph)
                Text("TODO")
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
