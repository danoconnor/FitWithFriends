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

    init(objectGraph: IObjectGraph) {
        self.objectGraph = objectGraph
        viewModel = WelcomeViewModel(authenticationManager: objectGraph.authenticationManager)
    }

    var body: some View {
        VStack {
            if viewModel.loginState.isFailed {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .padding(.leading)

                    Text(viewModel.loginState.errorMessage)
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

            Button(action: {
                self.viewModel.login()
            }, label: {
                SignInWithAppleButton()
                    .frame(height: 60)
                    .cornerRadius(16)
            })
            .padding()

            Spacer()
        }
        .background(Color("FwFBrandingColor"))
        .sheet(item: $viewModel.sheetToDisplay, onDismiss: {
            // If the user swipes down to dismiss the view, instead of using the button,
            // then make sure we mark the view as completed
            viewModel.dismissSheet()
        }) { state in
            switch state {
            case .firstLaunchWelcomeView:
                FirstLaunchWelcomeView(welcomeViewModel: viewModel)
            case .userInputView:
                UserNameInputView { firstName, lastName in
                    self.viewModel.createUserAndLogin(firstName: firstName, lastName: lastName)
                }
            case .none:
                // Should not happen
                EmptyView()
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(objectGraph: MockObjectGraph())
    }
}
