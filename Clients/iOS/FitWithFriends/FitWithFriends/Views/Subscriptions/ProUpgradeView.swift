//
//  ProUpgradeView.swift
//  FitWithFriends
//
//  Custom Pro paywall. Replaces the SubscriptionStoreView system layout with an
//  editorial hero + comparison table + ink CTA. Drives purchase + restore via
//  SubscriptionManager.purchaseProSubscription() / restorePurchases().
//

import SwiftUI

struct ProUpgradeView: View {
    private let subscriptionManager: ISubscriptionManager
    private let serverEnvironmentManager: IServerEnvironmentManager

    @State private var purchaseInProgress: Bool = false
    @State private var restoreInProgress: Bool = false
    @State private var errorMessage: String?

    /// Use SwiftUI's environment dismiss action so this view can be presented from
    /// any sheet (the homepage one or a nested sheet inside Settings/Create) and
    /// close itself cleanly. The presenting sheet's onDismiss handler is responsible
    /// for clearing any side-channel state (e.g. HomepageSheetViewModel.sheetToShow).
    @Environment(\.dismiss) private var dismiss

    init(subscriptionManager: ISubscriptionManager,
         serverEnvironmentManager: IServerEnvironmentManager) {
        self.subscriptionManager = subscriptionManager
        self.serverEnvironmentManager = serverEnvironmentManager
    }

    var body: some View {
        ZStack {
            Color("Bg").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    topRow
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    headerBlock
                        .padding(.horizontal, 22)

                    comparisonTable
                        .padding(.horizontal, 16)

                    if let errorMessage {
                        FWFErrorBanner(message: errorMessage)
                    }

                    ctaBlock
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var topRow: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Maybe later")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color("InkSoft"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color("SurfaceAlt")))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("proUpgradeDismiss")
            .accessibilityLabel("Close")
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            FWFTag(text: "FitWithFriends Pro",
                   color: Color("Sun"),
                   background: Color("Sun").opacity(0.18))

            FWFDisplay(parts: [("Make this ", false), ("actually", true), (" competitive.", false)],
                       size: 38,
                       italicColor: Color("Brand"))

            Text("Free gets you one competition with the standard ring scoring. Pro unlocks the rest of the app: more competitions, three scoring modes, custom rules, and the public weekly leaderboards.")
                .font(.system(size: 14))
                .foregroundStyle(Color("InkSoft"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Comparison

    private struct Feature { let title: String; let free: Bool; let pro: Bool }

    private let features: [Feature] = [
        Feature(title: "Apple Watch sync",                   free: true,  pro: true),
        Feature(title: "Apple Sign-In",                      free: true,  pro: true),
        Feature(title: "Push notifications",                 free: true,  pro: true),
        Feature(title: "1 private competition at a time",    free: true,  pro: true),
        Feature(title: "Up to 10 simultaneous competitions", free: false, pro: true),
        Feature(title: "Public weekly leaderboards",         free: false, pro: true),
        Feature(title: "Custom scoring (steps, workouts)",   free: false, pro: true),
        Feature(title: "Minimum-goal & daily-cap rules",     free: false, pro: true),
    ]

    private var comparisonTable: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Spacer()
                Text("Free")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color("InkMute"))
                    .frame(width: 50)
                Text("Pro")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color("Brand"))
                    .frame(width: 50)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider().background(Color("Border"))

            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                HStack {
                    Text(feature.title)
                        .font(.system(size: 14))
                        .foregroundStyle(Color("Ink"))
                    Spacer()
                    featureMark(on: feature.free).frame(width: 50)
                    featureMark(on: feature.pro).frame(width: 50)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(feature.free ? Color.clear : Color("Sun").opacity(0.08))

                if index < features.count - 1 {
                    Divider().background(Color("Border"))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color("Surface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color("Border"), lineWidth: 1)
        )
    }

    private func featureMark(on: Bool) -> some View {
        Group {
            if on {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color("Brand"))
            } else {
                Image(systemName: "minus")
                    .foregroundStyle(Color("InkFaint"))
            }
        }
        .font(.system(size: 16))
    }

    // MARK: - CTA

    private var ctaBlock: some View {
        VStack(spacing: 10) {
            FWFPrimaryButton(purchaseInProgress ? "Starting Pro…" : "Start Pro · $2.99/mo") {
                Task { await purchase() }
            }
            .disabled(purchaseInProgress || restoreInProgress)
            .opacity(purchaseInProgress ? 0.6 : 1)

            HStack(spacing: 4) {
                Text("Renews monthly. Cancel any time in iOS Settings.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color("InkMute"))
                Button {
                    Task { await restore() }
                } label: {
                    Text(restoreInProgress ? "Restoring…" : "Restore purchase")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color("Brand"))
                }
                .buttonStyle(.plain)
                .disabled(purchaseInProgress || restoreInProgress)
            }
        }
    }

    private func purchase() async {
        purchaseInProgress = true
        errorMessage = nil
        defer { purchaseInProgress = false }
        do {
            try await subscriptionManager.purchaseProSubscription()
            dismiss()
        } catch SubscriptionError.userCancelled {
            // User cancelled — no surface needed.
        } catch {
            Logger.traceError(message: "Pro purchase failed", error: error)
            errorMessage = "Couldn't complete the purchase. Please try again."
        }
    }

    private func restore() async {
        restoreInProgress = true
        errorMessage = nil
        defer { restoreInProgress = false }
        do {
            try await subscriptionManager.restorePurchases()
            if subscriptionManager.isUserPro {
                dismiss()
            } else {
                errorMessage = "We couldn't find an active Pro subscription on this Apple ID."
            }
        } catch {
            Logger.traceError(message: "Restore failed", error: error)
            errorMessage = "Restore failed. Please try again."
        }
    }
}
