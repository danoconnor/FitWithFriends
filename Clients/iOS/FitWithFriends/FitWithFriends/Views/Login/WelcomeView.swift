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
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color("FwFBrandingColor"),
                    Color("FwFBrandingColor").opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative circles
            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 250, height: 250)
                    .offset(x: geo.size.width * 0.6, y: -60)

                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 180, height: 180)
                    .offset(x: -40, y: geo.size.height * 0.65)
            }

            VStack(spacing: 0) {
                if viewModel.loginState.isFailed {
                    FWFErrorBanner(message: viewModel.loginState.errorMessage)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                // App icon and title
                VStack(spacing: 12) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                    Text("Fit With Friends")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Compete. Move. Win.")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                // Sign in button
                Button(action: {
                    self.viewModel.login()
                }, label: {
                    SignInWithAppleButton()
                        .frame(height: 50)
                        .cornerRadius(12)
                })
                .padding(.horizontal, 40)
                .padding(.bottom, 48)
            }
        }
        .animation(.spring(duration: 0.4), value: viewModel.loginState.isFailed)
        .sheet(item: $viewModel.sheetToDisplay, onDismiss: {
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
