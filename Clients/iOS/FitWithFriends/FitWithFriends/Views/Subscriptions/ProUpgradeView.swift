//
//  ProUpgradeView.swift
//  FitWithFriends
//

import StoreKit
import SwiftUI

struct ProUpgradeView: View {
    @ObservedObject private var homepageSheetViewModel: HomepageSheetViewModel
    private let subscriptionManager: ISubscriptionManager

    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

    init(homepageSheetViewModel: HomepageSheetViewModel,
         subscriptionManager: ISubscriptionManager) {
        self.homepageSheetViewModel = homepageSheetViewModel
        self.subscriptionManager = subscriptionManager
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Color("FwFBrandingColor"))

                        Text("Upgrade to Pro")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Get the most out of Fit with Friends")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        BenefitRow(icon: "globe",
                                   title: "Public Competitions",
                                   description: "Join weekly public competitions and compete with the community")

                        BenefitRow(icon: "person.3.fill",
                                   title: "More Competitions",
                                   description: "Join up to 10 private competitions at the same time")
                    }
                    .fwfCard()
                    .padding(.horizontal, 16)

                    if let errorMessage = errorMessage {
                        FWFErrorBanner(message: errorMessage)
                    }

                    // Purchase button
                    FWFPrimaryButton("Subscribe", icon: "star.fill") {
                        Task {
                            await purchase()
                        }
                    }
                    .disabled(isPurchasing || isRestoring)
                    .padding(.horizontal, 16)

                    // Restore purchases
                    Button("Restore Purchases") {
                        Task {
                            await restore()
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .disabled(isPurchasing || isRestoring)

                    if isPurchasing || isRestoring {
                        ProgressView()
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        homepageSheetViewModel.dismissCurrentSheet()
                    }
                }
            }
        }
    }

    private func purchase() async {
        isPurchasing = true
        errorMessage = nil

        do {
            try await subscriptionManager.purchaseProSubscription()
            homepageSheetViewModel.dismissCurrentSheet()
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }

        isPurchasing = false
    }

    private func restore() async {
        isRestoring = true
        errorMessage = nil

        do {
            try await subscriptionManager.restorePurchases()
            if subscriptionManager.isUserPro {
                homepageSheetViewModel.dismissCurrentSheet()
            } else {
                errorMessage = "No active subscription found."
            }
        } catch {
            errorMessage = "Restore failed. Please try again."
        }

        isRestoring = false
    }
}

private struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color("FwFBrandingColor"))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
