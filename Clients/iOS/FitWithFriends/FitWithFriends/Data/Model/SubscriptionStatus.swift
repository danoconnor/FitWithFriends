//
//  SubscriptionStatus.swift
//  FitWithFriends
//

import Foundation

public struct SubscriptionStatus: Decodable {
    let isPro: Bool
    let maxActiveCompetitions: Int
}
