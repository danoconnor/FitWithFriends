//
//  SubscriptionManager.swift
//  FitWithFriends
//

import Combine
import Foundation
import StoreKit

public class SubscriptionManager: ISubscriptionManager, ObservableObject {
    private static let proMonthlyProductId = "com.danoconnor.FitWithFriends.pro.monthly"

    private let subscriptionService: ISubscriptionService

    private var transactionUpdateTask: Task<Void, Never>?

    @Published private(set) var isUserPro: Bool = false
    var isUserProPublisher: Published<Bool>.Publisher { $isUserPro }

    init(subscriptionService: ISubscriptionService) {
        self.subscriptionService = subscriptionService

        transactionUpdateTask = listenForTransactionUpdates()
    }

    deinit {
        transactionUpdateTask?.cancel()
    }

    func purchaseProSubscription() async throws {
        let products = try await Product.products(for: [Self.proMonthlyProductId])

        guard let product = products.first else {
            Logger.traceError(message: "Could not find Pro subscription product with id \(Self.proMonthlyProductId)")
            throw SubscriptionError.productNotFound
        }

        let purchaseResult = try await product.purchase()

        switch purchaseResult {
        case .success(let verification):
            let transaction = try verification.payloadValue

            let status = try await subscriptionService.validateTransaction(signedTransaction: transaction.jwsRepresentation)
            Logger.traceInfo(message: "Transaction validated by server, isPro: \(status.isPro)")

            await MainActor.run {
                isUserPro = true
            }

            await transaction.finish()

        case .userCancelled:
            Logger.traceInfo(message: "User cancelled Pro subscription purchase")
            throw SubscriptionError.userCancelled

        case .pending:
            Logger.traceInfo(message: "Pro subscription purchase is pending")
            throw SubscriptionError.purchasePending

        @unknown default:
            Logger.traceWarning(message: "Unknown purchase result for Pro subscription")
            throw SubscriptionError.unknown
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await checkSubscriptionStatus()
    }

    func checkSubscriptionStatus() async {
        var foundValidEntitlement = false

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else {
                Logger.traceWarning(message: "Skipping unverified entitlement in checkSubscriptionStatus")
                continue
            }

            guard transaction.productID == Self.proMonthlyProductId else {
                continue
            }

            if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                Logger.traceInfo(message: "Found expired Pro entitlement, expiration: \(expirationDate)")
                continue
            }

            Logger.traceInfo(message: "Found valid Pro entitlement")
            foundValidEntitlement = true
            break
        }

        await MainActor.run {
            isUserPro = foundValidEntitlement
        }
    }

    // MARK: - Private

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                guard let self = self else { return }

                guard case .verified(let transaction) = update else {
                    Logger.traceWarning(message: "Received unverified transaction update, skipping")
                    continue
                }

                guard transaction.productID == Self.proMonthlyProductId else {
                    continue
                }

                if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                    Logger.traceInfo(message: "Received expired transaction update for Pro subscription")
                    await MainActor.run {
                        self.isUserPro = false
                    }
                } else {
                    Logger.traceInfo(message: "Received valid transaction update, validating with server")
                    do {
                        let status = try await self.subscriptionService.validateTransaction(signedTransaction: transaction.jwsRepresentation)
                        Logger.traceInfo(message: "Background transaction validated, isPro: \(status.isPro)")
                        await MainActor.run {
                            self.isUserPro = status.isPro
                        }
                    } catch {
                        Logger.traceError(message: "Failed to validate background transaction with server", error: error)
                    }
                }

                await transaction.finish()
            }
        }
    }
}

// MARK: - SubscriptionError

enum SubscriptionError: Error {
    case productNotFound
    case userCancelled
    case purchasePending
    case unknown
}
