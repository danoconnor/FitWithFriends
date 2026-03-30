//
//  ISubscriptionService.swift
//  FitWithFriends
//

import Foundation

public protocol ISubscriptionService {
    /// Sends a signed StoreKit 2 transaction to the backend for validation
    /// - Parameter signedTransaction: The JWS string from StoreKit 2
    /// - Returns: The subscription status after validation
    func validateTransaction(signedTransaction: String) async throws -> SubscriptionStatus
}
