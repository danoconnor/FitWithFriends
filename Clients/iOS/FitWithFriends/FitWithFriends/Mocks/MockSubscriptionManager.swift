//
//  MockSubscriptionManager.swift
//  FitWithFriends
//

import Foundation

public class MockSubscriptionManager: ISubscriptionManager {
    @Published var return_isUserPro: Bool = false
    public var isUserPro: Bool {
        return_isUserPro
    }

    public var isUserProPublisher: Published<Bool>.Publisher { $return_isUserPro }

    public init() {}

    public var purchaseProSubscriptionCallCount = 0
    public var return_purchaseProSubscription_error: Error?
    public func purchaseProSubscription() async throws {
        purchaseProSubscriptionCallCount += 1

        if let error = return_purchaseProSubscription_error {
            throw error
        }
    }

    public var restorePurchasesCallCount = 0
    public var return_restorePurchases_error: Error?
    public func restorePurchases() async throws {
        restorePurchasesCallCount += 1

        if let error = return_restorePurchases_error {
            throw error
        }
    }

    public var checkSubscriptionStatusCallCount = 0
    public func checkSubscriptionStatus() async {
        checkSubscriptionStatusCallCount += 1
    }
}
