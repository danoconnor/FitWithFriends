//
//  SubscriptionService.swift
//  FitWithFriends
//

import Foundation

public class SubscriptionService: ServiceBase, ISubscriptionService {
    public func validateTransaction(signedTransaction: String) async throws -> SubscriptionStatus {
        let requestBody: [String: String] = [
            "signedTransaction": signedTransaction
        ]

        return try await makeRequestWithUserAuthentication(url: "\(serverEnvironmentManager.baseUrl)/subscriptions/validateTransaction",
                                                           method: .post,
                                                           body: requestBody)
    }
}
