//
//  ISubscriptionManager.swift
//  FitWithFriends
//

import Foundation

protocol ISubscriptionManager: AnyObject {
    /// Whether the current user has an active Pro subscription
    var isUserPro: Bool { get }

    /// Publisher for changes to isUserPro
    var isUserProPublisher: Published<Bool>.Publisher { get }

    /// Purchase the Pro subscription
    func purchaseProSubscription() async throws

    /// Restore previous purchases
    func restorePurchases() async throws

    /// Check current subscription status (called on app launch)
    func checkSubscriptionStatus() async
}
