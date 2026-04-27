//
//  ProUpgradeView.swift
//  FitWithFriends
//

import StoreKit
import SwiftUI

struct ProUpgradeView: View {
    @ObservedObject private var homepageSheetViewModel: HomepageSheetViewModel
    private let subscriptionManager: ISubscriptionManager

    init(homepageSheetViewModel: HomepageSheetViewModel,
         subscriptionManager: ISubscriptionManager) {
        self.homepageSheetViewModel = homepageSheetViewModel
        self.subscriptionManager = subscriptionManager
    }

    var body: some View {
        SubscriptionStoreView(productIDs: ["com.danoconnor.FitWithFriends.pro.monthly"]) {
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
            }
        }
        .onInAppPurchaseCompletion { _, result in
            guard case .success(let purchaseResult) = result,
                  case .success = purchaseResult else { return }
            await subscriptionManager.checkSubscriptionStatus()
            homepageSheetViewModel.dismissCurrentSheet()
        }
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
