//
//  LoginView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import SwiftUI

struct LoginView: View {
    let objectGraph: IObjectGraph

    @State private var username = ""
    @State private var password = ""

    @ObservedObject private var viewModel: LoginViewModel

    init(objectGraph: IObjectGraph) {
        self.objectGraph = objectGraph
        viewModel = LoginViewModel(authenticationManager: objectGraph.authenticationManager)
    }

    var body: some View {
        VStack {
            Spacer()

            Text("Login")
                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)

            TextField("Username", text: $username)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)

            SecureField("Password", text: $password)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.password)

            Spacer()
            Spacer()

            if viewModel.state.isFailed {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .padding(.leading)

                    Text(viewModel.state.errorMessage)
                        .font(.subheadline)
                        .padding(.trailing)

                    Spacer()
                }
                .background(Color.red)
            }

            Button("Submit") {
                viewModel.login(username: username, password: password)
            }
            .font(.title2)
            .padding()
            .disabled(viewModel.state == .inProgress)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(objectGraph: MockObjectGraph())
    }
}
