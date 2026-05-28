//
//  WelcomeView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/22/20.
//

import SwiftUI

struct WelcomeView: View {
    private let objectGraph: IObjectGraph
    @StateObject private var viewModel: WelcomeViewModel

    init(objectGraph: IObjectGraph) {
        self.objectGraph = objectGraph
        _viewModel = StateObject(wrappedValue: WelcomeViewModel(authenticationManager: objectGraph.authenticationManager))
    }

    var body: some View {
        ZStack {
            Color("Bg").ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.loginState.isFailed {
                    FWFErrorBanner(message: viewModel.loginState.errorMessage)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                wordmarkRow
                    .padding(.horizontal, 22)
                    .padding(.top, 12)

                Spacer(minLength: 24)

                heroBlock
                    .padding(.horizontal, 22)

                Spacer(minLength: 20)

                LeaderboardPreviewCard()
                    .padding(.horizontal, 28)

                Spacer()

                signInBlock
                    .padding(.horizontal, 22)
                    .padding(.bottom, 32)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("welcomeScreen")
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

    // MARK: - Subviews

    private var wordmarkRow: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color("Brand"))
                Image(systemName: "figure.run")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)

            Text("FitWithFriends")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color("Ink"))

            Spacer()
        }
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            FWFDisplay(
                parts: [
                    ("Close rings.\n", false),
                    ("Beat your friends.", true)
                ],
                size: 48,
                color: Color("Ink"),
                italicColor: Color("Brand")
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Weekly fitness competitions with the people in your group chat — powered by Apple Watch.")
                .font(.system(size: 16))
                .foregroundStyle(Color("InkSoft"))
                .lineSpacing(2)
                .frame(maxWidth: 320, alignment: .leading)
        }
    }

    @ViewBuilder
    private var signInBlock: some View {
        if viewModel.loginState == .inProgress {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color("Ink"))
                .scaleEffect(1.5)
                .frame(height: 54)
                .accessibilityIdentifier("loginProgressSpinner")
        } else {
            VStack(spacing: 10) {
                Button {
                    self.viewModel.login()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "applelogo")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Sign in with Apple")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    // BgDeep inverts with Ink in both modes — see FWFPrimaryButton.
                    .foregroundStyle(Color("BgDeep"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color("Ink"))
                    )
                }
                .accessibilityIdentifier("signInButton")
                .buttonStyle(.plain)

                Text("Free to use · Requires Apple Watch or iPhone health data")
                    .font(.system(size: 12))
                    .foregroundStyle(Color("InkMute"))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Leaderboard preview card

/// A small static-looking "what this product is" demo card on the welcome screen.
/// Sells the product faster than any tagline because the user can see the actual
/// shape of a competition leaderboard before signing in.
private struct LeaderboardPreviewCard: View {
    private struct Row { let name: String; let pts: Int; let progress: Double; let medal: Color? }

    private let rows: [Row] = [
        Row(name: "Alice Chen",    pts: 480, progress: 1.00, medal: Color("Gold")),
        Row(name: "You",           pts: 422, progress: 0.88, medal: Color("Silver")),
        Row(name: "Marcus Lee",    pts: 365, progress: 0.76, medal: Color("Bronze")),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                FWFTag(text: "Friends Challenge", color: Color("Brand"), background: Color("BrandSoft"))
                Spacer()
                Text("4d left")
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color("InkMute"))
            }

            VStack(spacing: 10) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 10) {
                        FWFAvatar(name: row.name, size: 26, ring: row.medal)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.name)
                                .font(.system(size: 13, weight: row.name == "You" ? .bold : .medium))
                                .foregroundStyle(Color("Ink"))

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color("BrandSoft"))
                                        .frame(height: 4)
                                    Capsule()
                                        .fill(Color("Brand"))
                                        .frame(width: geo.size.width * row.progress, height: 4)
                                }
                            }
                            .frame(height: 4)
                        }

                        Text("\(row.pts)")
                            .font(.system(size: 13, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Color("Ink"))
                    }
                }
            }
        }
        .fwfCard(padding: 14)
        .rotationEffect(.degrees(-1.5))
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(objectGraph: MockObjectGraph())
    }
}
