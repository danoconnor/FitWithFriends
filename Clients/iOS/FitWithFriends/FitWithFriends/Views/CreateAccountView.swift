//
//  CreateAccountView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import SwiftUI

struct CreateAccountView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""
    @State private var displayName = ""

    @ObservedObject private var viewModel = CreateAccountViewModel()

    var body: some View {
        VStack {
            Text("Create new account")
                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                .padding()

            Spacer()

            TextField("What's your name?", text: $displayName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Choose a username", text: $username)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Set your password", text: $password)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.newPassword)

            TextField("Confirm your password", text: $passwordConfirmation)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.newPassword)

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

            Button("Create") {
                viewModel.createAccount(username: username,
                                        password: password,
                                        passwordConfirmation: passwordConfirmation,
                                        displayName: displayName)
            }
                .font(.title2)
                .padding()
                .disabled(viewModel.state == .inProgress)
        }
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView()
    }
}
