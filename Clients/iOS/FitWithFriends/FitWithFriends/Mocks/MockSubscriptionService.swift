//
//  MockSubscriptionService.swift
//  FitWithFriends
//

import Foundation

public class MockSubscriptionService: ISubscriptionService {
    public var param_validateTransaction_signedTransaction: String?
    public var return_validateTransaction: SubscriptionStatus?
    public var return_validateTransaction_error: Error?
    public var validateTransactionCallCount = 0

    public init() {}

    public func validateTransaction(signedTransaction: String) async throws -> SubscriptionStatus {
        validateTransactionCallCount += 1
        param_validateTransaction_signedTransaction = signedTransaction

        if let error = return_validateTransaction_error {
            throw error
        }

        if let retVal = return_validateTransaction {
            return retVal
        } else {
            throw HttpError.generic
        }
    }
}
